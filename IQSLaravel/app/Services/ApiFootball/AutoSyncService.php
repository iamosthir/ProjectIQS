<?php

namespace App\Services\ApiFootball;

use App\Models\Fixture;
use App\Models\Season;
use Illuminate\Support\Facades\Cache;

/**
 * Orchestrates the automatic API-Football sync for every league season
 * subscribed via `seasons.auto_sync` (the admin Sync Console toggles it).
 *
 * Runs from the every-minute `sync:auto` tick and self-paces per tier using
 * the season watermark columns + the configured cadences
 * (services.api_football.auto_sync), so one scheduler entry drives fixtures,
 * standings, teams, top scorers and pre-match lineups without hammering the
 * request budget. Manual (`source = manual`) rows live in the same tables and
 * are never touched — the upsert layer keys on (source, external_id) and
 * skips locked/manual data by design.
 */
class AutoSyncService
{
    public function __construct(
        private readonly ApiFootballClient $client,
        private readonly FixtureSync $fixtures,
        private readonly StandingSync $standings,
        private readonly TeamSync $teams,
        private readonly TopScorerSync $topScorers,
        private readonly FixtureDetailSync $details,
    ) {}

    /** tier => watermark column */
    private const TIERS = [
        'fixtures' => 'fixtures_synced_at',
        'standings' => 'standings_synced_at',
        'teams' => 'teams_synced_at',
        'top_scorers' => 'top_scorers_synced_at',
    ];

    /** tier => [auto_sync config key, default minutes] */
    private const TIER_INTERVALS = [
        'fixtures' => ['fixtures_minutes', 15],
        'standings' => ['standings_minutes', 60],
        'teams' => ['teams_minutes', 1440],
        'top_scorers' => ['top_scorers_minutes', 360],
    ];

    /**
     * Run every due sync tier for every subscribed season.
     *
     * @return array{fixtures: int, standings: int, teams: int, top_scorers: int, lineups: int, details: int, errors: list<string>}
     */
    public function run(): array
    {
        $summary = $this->emptySummary();

        $seasons = Season::query()
            ->autoSync()
            ->whereHas('league', fn ($q) => $q->apiFootball()->whereNotNull('external_id'))
            ->with('league')
            ->get();

        foreach ($seasons as $season) {
            if (! $this->syncTiers($season, $this->dueTiers($season), $summary)) {
                return $summary; // budget/rate limit — resume next tick
            }
        }

        $summary['lineups'] = $this->syncUpcomingLineups($summary);
        $summary['details'] = $this->backfillFinishedDetails($summary);

        return $summary;
    }

    /**
     * Force-run EVERY tier for one season now, regardless of cadence — the
     * Sync Console "sync now" button.
     *
     * @return array{fixtures: int, standings: int, teams: int, top_scorers: int, lineups: int, details: int, errors: list<string>}
     */
    public function runSeason(Season $season): array
    {
        $season->loadMissing('league');
        $summary = $this->emptySummary();

        if ($this->syncTiers($season, self::TIERS, $summary)) {
            // Top up a batch of missing fixture details too, so repeated
            // "sync now" presses progressively complete the season.
            $summary['details'] = $this->backfillFinishedDetails($summary, $season);
        }

        return $summary;
    }

    /**
     * Run the given tiers for one season, updating watermarks per success.
     * Returns false when the whole run must stop (budget gone / provider
     * rate limit); other tier failures are recorded and skipped past.
     *
     * @param  array<string, string>  $tiers  tier => watermark column
     * @param  array{fixtures: int, standings: int, teams: int, top_scorers: int, lineups: int, errors: list<string>}  $summary
     */
    protected function syncTiers(Season $season, array $tiers, array &$summary): bool
    {
        $league = (int) $season->league->external_id;

        foreach ($tiers as $tier => $watermarkColumn) {
            if (! $this->client->hasBudget()) {
                $summary['errors'][] = 'Daily request budget exhausted — auto sync paused until tomorrow.';

                return false;
            }

            try {
                $summary[$tier] += match ($tier) {
                    'fixtures' => $this->fixtures->syncSeason($league, $season->year),
                    'standings' => $this->standings->sync($league, $season->year),
                    'teams' => $this->teams->sync($league, $season->year),
                    'top_scorers' => $this->topScorers->sync($league, $season->year),
                };

                $season->forceFill([$watermarkColumn => now()])->save();
            } catch (ApiFootballException $e) {
                $summary['errors'][] = "{$tier} (league {$league}, {$season->year}): {$e->getMessage()}";

                if ($e->rateLimited) {
                    return false;
                }
            }
        }

        return true;
    }

    /**
     * Tiers whose cadence has elapsed for this season, as tier => watermark
     * column. Null watermarks (fresh subscriptions) are always due, so a
     * newly toggled season fully populates within a minute.
     *
     * @return array<string, string>
     */
    protected function dueTiers(Season $season): array
    {
        $config = (array) config('services.api_football.auto_sync');
        $due = [];

        foreach (self::TIERS as $tier => $column) {
            [$key, $default] = self::TIER_INTERVALS[$tier];
            $minutes = (int) ($config[$key] ?? $default);
            $lastRun = $season->getAttribute($column);

            if ($lastRun === null || $lastRun->lte(now()->subMinutes($minutes))) {
                $due[$tier] = $column;
            }
        }

        return $due;
    }

    /**
     * Backfill events/lineups/statistics for finished fixtures that never
     * got their final detail pull (1 request per fixture, newest first —
     * the matches users actually open). Runs after the score tiers and only
     * while the daily budget stays above the configured floor, so it soaks
     * up spare quota without ever starving live/score syncs. Fixtures are
     * stamped `details_synced_at` even when the provider has nothing, so
     * nothing is requested twice.
     *
     * @param  array{errors: list<string>}  $summary
     */
    protected function backfillFinishedDetails(array &$summary, ?Season $season = null): int
    {
        $config = (array) config('services.api_football.auto_sync');
        $perRun = (int) ($config['details_backfill_per_run'] ?? 10);
        $floor = (int) ($config['details_budget_floor'] ?? 20);

        if ($perRun <= 0) {
            return 0;
        }

        $fixtures = Fixture::query()
            ->apiFootball()
            ->where('status_group', 'finished')
            ->whereNull('details_synced_at')
            ->when(
                $season !== null,
                fn ($q) => $q->where('season_id', $season->id),
                fn ($q) => $q->whereHas('season', fn ($s) => $s->autoSync()),
            )
            ->orderByDesc('match_datetime')
            ->limit($perRun)
            ->get();

        $synced = 0;

        foreach ($fixtures as $fixture) {
            if ($this->client->remainingBudget() <= $floor) {
                break; // leave headroom for the score/live syncs
            }

            try {
                $this->details->sync($fixture);
                $synced++;
            } catch (ApiFootballException $e) {
                $summary['errors'][] = "details (fixture {$fixture->id}): {$e->getMessage()}";

                if ($e->rateLimited) {
                    break;
                }
            }
        }

        return $synced;
    }

    /**
     * @return array{fixtures: int, standings: int, teams: int, top_scorers: int, lineups: int, details: int, errors: list<string>}
     */
    private function emptySummary(): array
    {
        return ['fixtures' => 0, 'standings' => 0, 'teams' => 0, 'top_scorers' => 0, 'lineups' => 0, 'details' => 0, 'errors' => []];
    }

    /**
     * Pull pre-match lineups for subscribed fixtures kicking off soon.
     * API-Football publishes lineups ~20-40 minutes before kickoff; each
     * fixture is retried on a cache throttle until its lineups exist.
     *
     * @param  array{errors: list<string>}  $summary
     */
    protected function syncUpcomingLineups(array &$summary): int
    {
        $config = (array) config('services.api_football.auto_sync');
        $lookahead = (int) ($config['lineup_lookahead_minutes'] ?? 60);
        $retry = (int) ($config['lineup_retry_minutes'] ?? 15);

        $upcoming = Fixture::query()
            ->apiFootball()
            ->where('has_lineups', false)
            ->whereBetween('match_datetime', [now(), now()->addMinutes($lookahead)])
            ->whereHas('season', fn ($q) => $q->autoSync())
            ->get();

        $synced = 0;

        foreach ($upcoming as $fixture) {
            if (! $this->client->hasBudget()) {
                break;
            }

            // One attempt per retry window per fixture.
            if (! Cache::add("auto_sync:lineups:{$fixture->id}", 1, now()->addMinutes($retry))) {
                continue;
            }

            try {
                $this->details->sync($fixture);
                $synced++;
            } catch (ApiFootballException $e) {
                $summary['errors'][] = "lineups (fixture {$fixture->id}): {$e->getMessage()}";

                if ($e->rateLimited) {
                    break;
                }
            }
        }

        return $synced;
    }
}
