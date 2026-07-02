<?php

namespace App\Services\ApiFootball;

use App\Models\ApiFootballSyncLog;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Throwable;

/**
 * Thin HTTP wrapper over API-Football v3 (§2.4). Injects the key + timezone,
 * parses the `{ errors, response, ... }` envelope, records every call in
 * api_football_sync_logs, tracks the daily request budget, and throws on
 * API `errors[]` / HTTP failures.
 */
class ApiFootballClient
{
    public function __construct(
        private readonly ?string $key,
        private readonly string $baseUrl,
        private readonly string $timezone,
        private readonly int $dailyLimit,
    ) {}

    /**
     * Perform a GET and return the decoded `response` array.
     *
     * @param  array<string, mixed>  $params
     * @return array<int, array<string, mixed>>
     */
    public function get(string $endpoint, array $params = []): array
    {
        $this->guardDailyBudget($endpoint, $params);

        // Only a few endpoints accept `timezone`; sending it to the others
        // (leagues, teams, standings, top-scorers, ...) makes API-Football
        // reject the call with "The Timezone field do not exist."
        if (in_array(ltrim($endpoint, '/'), ['fixtures', 'fixtures/rounds', 'injuries'], true)) {
            $params = array_merge(['timezone' => $this->timezone], $params);
        }
        $startedAt = microtime(true);

        try {
            $response = Http::baseUrl($this->baseUrl)
                ->withHeaders(['x-apisports-key' => (string) $this->key])
                ->timeout(30)
                ->retry(2, 250, throw: false)
                ->get('/'.ltrim($endpoint, '/'), $params);
        } catch (Throwable $e) {
            $this->log($endpoint, $params, 'failed', null, null, null, $e->getMessage(), $startedAt);

            throw new ApiFootballException("API-Football request failed: {$e->getMessage()}");
        }

        $this->incrementDailyCount();

        $remaining = $response->header('x-ratelimit-requests-remaining');
        $remaining = $remaining !== null ? (int) $remaining : null;
        $json = $response->json() ?? [];
        $errors = $json['errors'] ?? [];

        if (! $response->successful() || ! empty($errors)) {
            $rateLimited = $response->status() === 429;
            $message = empty($errors) ? "HTTP {$response->status()}" : json_encode($errors);

            $this->log(
                $endpoint, $params,
                $rateLimited ? 'rate_limited' : 'failed',
                $response->status(), 0, $remaining, $message, $startedAt,
            );

            throw new ApiFootballException("API-Football error: {$message}", $rateLimited);
        }

        $data = $json['response'] ?? [];

        $this->log($endpoint, $params, 'success', $response->status(), count($data), $remaining, null, $startedAt);

        return $data;
    }

    /**
     * Whether the daily request budget still has headroom.
     */
    public function hasBudget(): bool
    {
        return $this->dailyCount() < $this->dailyLimit;
    }

    public function remainingBudget(): int
    {
        return max(0, $this->dailyLimit - $this->dailyCount());
    }

    /**
     * @param  array<string, mixed>  $params
     */
    protected function guardDailyBudget(string $endpoint, array $params): void
    {
        if ($this->hasBudget()) {
            return;
        }

        $this->log($endpoint, $params, 'rate_limited', null, 0, 0, 'Daily request budget exhausted', microtime(true));

        throw new ApiFootballException('API-Football daily request budget exhausted.', rateLimited: true);
    }

    protected function dailyCount(): int
    {
        return (int) Cache::get($this->budgetKey(), 0);
    }

    protected function incrementDailyCount(): void
    {
        $key = $this->budgetKey();

        if (Cache::get($key) === null) {
            Cache::put($key, 0, Carbon::tomorrow()->startOfDay());
        }

        Cache::increment($key);
    }

    protected function budgetKey(): string
    {
        return 'api_football:requests:'.now()->toDateString();
    }

    /**
     * @param  array<string, mixed>  $params
     */
    protected function log(
        string $endpoint,
        array $params,
        string $status,
        ?int $httpStatus,
        ?int $records,
        ?int $remaining,
        ?string $error,
        float $startedAt,
    ): void {
        ApiFootballSyncLog::create([
            'endpoint' => $endpoint,
            'parameters' => $params,
            'status' => $status,
            'http_status' => $httpStatus,
            'records_processed' => $records,
            'requests_remaining' => $remaining,
            'error_message' => $error,
            'duration_ms' => (int) round((microtime(true) - $startedAt) * 1000),
        ]);
    }
}
