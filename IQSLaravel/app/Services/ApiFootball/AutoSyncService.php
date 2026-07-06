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

    /**
     * Run every due sync tier for every subscribed season.
     *
     * @return array{fixtures: int, standings: int, teams: int, top_scorers: int, lineups: int, errors: list<string>}
     */
    public function run(): array
    {
        $summary = ['fixtures' => 0, 'standings' => 0, 'teams' => 0, 'top_scorers' => 0, 'lineups' => 0, 'errors' => []];

        $seasons = Season::query()
            ->autoSync()
            ->whereHas('league', fn ($q) => $q->apiFootball()->whereNotNull('external_id'))
            ->with('league')
            ->get();

        foreach ($seasons as $season) {
            foreach ($this->dueTiers($season) as $tier => $watermarkColumn) {
                if (! $this->client->hasBudget()) {
                    $summary['errors'][] = 'Daily request budget exhausted — auto sync paused until tomorrow.';

                    return $summary;
                }

                $league = (int) $season->league->external_id;

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
                        return $summary;
                    }
                }
            }
        }

        $summary['lineups'] = $this->syncUpcomingLineups($summary);

        return $summary;
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

        $tiers = [
            'fixtures' => ['fixtures_synced_at', (int) ($config['fixtures_minutes'] ?? 15)],
            'standings' => ['standings_synced_at', (int) ($config['standings_minutes'] ?? 60)],
            'teams' => ['teams_synced_at', (int) ($config['teams_minutes'] ?? 1440)],
            'top_scorers' => ['top_scorers_synced_at', (int) ($config['top_scorers_minutes'] ?? 360)],
        ];

        $due = [];

        foreach ($tiers as $tier => [$column, $minutes]) {
            $lastRun = $season->getAttribute($column);

            if ($lastRun === null || $lastRun->lte(now()->subMinutes($minutes))) {
                $due[$tier] = $column;
            }
        }

        return $due;
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
