<?php

namespace App\Http\Controllers\Admin\Matches;

use App\Http\Controllers\Controller;
use App\Http\Resources\Admin\SeasonAdminResource;
use App\Http\Resources\Admin\SyncLogResource;
use App\Models\ApiFootballSyncLog;
use App\Models\Country;
use App\Models\Fixture;
use App\Models\Season;
use App\Services\ApiFootball\ApiFootballClient;
use App\Services\ApiFootball\ApiFootballException;
use App\Services\ApiFootball\AutoSyncService;
use App\Services\ApiFootball\CountrySync;
use App\Services\ApiFootball\FixtureDetailSync;
use App\Services\ApiFootball\FixtureSync;
use App\Services\ApiFootball\LeagueSync;
use App\Services\ApiFootball\StandingSync;
use App\Services\ApiFootball\TeamSync;
use App\Services\ApiFootball\TopScorerSync;
use App\Support\Enums\Source;
use Closure;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Admin Sync Console — triggers the API-Football syncs and exposes the log.
 */
class SyncController extends Controller
{
    public function leagues(Request $request, LeagueSync $sync): JsonResponse
    {
        $data = $request->validate(['country' => ['nullable', 'string', 'max:100']]);

        // `country` scopes the import ("Iraq", "England", "World"…); the
        // legacy `iraqi` flag maps onto it; neither → all countries.
        $country = ($data['country'] ?? null) ?: ($request->boolean('iraqi') ? 'Iraq' : null);

        return $this->run(fn () => $sync->sync($country));
    }

    /**
     * Refresh the API-Football countries list (feeds the country picker).
     */
    public function syncCountries(CountrySync $sync): JsonResponse
    {
        return $this->run(fn () => $sync->sync());
    }

    /**
     * Country options for the Sync Console picker (~170 rows, unpaginated).
     */
    public function countryOptions(): JsonResponse
    {
        return $this->ok(
            Country::query()
                ->orderBy('name_en')
                ->get(['id', 'name_ar', 'name_en', 'code', 'flag_path'])
        );
    }

    public function teams(Request $request, TeamSync $sync): JsonResponse
    {
        ['league' => $league, 'season' => $season] = $this->leagueSeason($request);

        return $this->run(fn () => $sync->sync($league, $season));
    }

    public function standings(Request $request, StandingSync $sync): JsonResponse
    {
        ['league' => $league, 'season' => $season] = $this->leagueSeason($request);

        return $this->run(fn () => $sync->sync($league, $season));
    }

    public function fixtures(Request $request, FixtureSync $sync): JsonResponse
    {
        ['league' => $league, 'season' => $season] = $this->leagueSeason($request);

        return $this->run(fn () => $sync->syncSeason($league, $season));
    }

    public function topScorers(Request $request, TopScorerSync $sync): JsonResponse
    {
        ['league' => $league, 'season' => $season] = $this->leagueSeason($request);

        return $this->run(fn () => $sync->sync($league, $season));
    }

    public function fixtureDetails(Fixture $fixture, FixtureDetailSync $sync): JsonResponse
    {
        return $this->run(function () use ($sync, $fixture): int {
            $sync->sync($fixture);

            return 1;
        });
    }

    /**
     * Auto-sync overview: the subscribed league seasons with their per-tier
     * watermarks, plus the remaining daily budget and configured cadences.
     */
    public function autoStatus(ApiFootballClient $client): JsonResponse
    {
        $seasons = Season::query()
            ->autoSync()
            ->with('league')
            ->withCount([
                'fixtures',
                'fixtures as detailed_fixtures_count' => fn ($q) => $q->whereNotNull('details_synced_at'),
            ])
            ->orderByDesc('year')
            ->get();

        return $this->ok([
            'seasons' => SeasonAdminResource::collection($seasons),
            'budget_remaining' => $client->remainingBudget(),
            'intervals' => config('services.api_football.auto_sync'),
            'live_poll_seconds' => config('services.api_football.live_poll_seconds'),
        ]);
    }

    /**
     * Subscribe/unsubscribe a league season to the automatic sync. Enabling
     * resets the tier watermarks so the next `sync:auto` tick (≤1 minute)
     * performs a full initial pull.
     */
    public function toggleAuto(Request $request, Season $season): JsonResponse
    {
        $enabled = $request->validate(['enabled' => ['required', 'boolean']])['enabled'];

        $season->loadMissing('league');

        if ($enabled && ($season->league->source !== Source::ApiFootball || $season->league->external_id === null)) {
            return $this->fail(__('Only seasons of API-Football leagues can be auto-synced. Manual leagues are maintained from the match module.'), null, 422);
        }

        // Subscribing means "show this league in the app" — activate leagues
        // that were imported inactive (non-Iraqi default) so the synced data
        // is actually reachable and the live poll stores their fixtures.
        if ($enabled && ! $season->league->is_active) {
            $season->league->update(['is_active' => true]);
        }

        $season->forceFill($enabled ? [
            'auto_sync' => true,
            'fixtures_synced_at' => null,
            'standings_synced_at' => null,
            'teams_synced_at' => null,
            'top_scorers_synced_at' => null,
        ] : ['auto_sync' => false])->save();

        return $this->ok(
            new SeasonAdminResource($season),
            $enabled ? __('Auto-sync enabled — the first full pull starts within a minute.') : __('Auto-sync disabled.'),
        );
    }

    /**
     * "Sync now" — force-run all tiers (fixtures/standings/teams/scorers)
     * for one season immediately, regardless of cadence or the scheduler.
     */
    public function runAutoSeason(Season $season, AutoSyncService $sync): JsonResponse
    {
        $season->loadMissing('league');

        if ($season->league->source !== Source::ApiFootball || $season->league->external_id === null) {
            return $this->fail(__('Only seasons of API-Football leagues can be synced.'), null, 422);
        }

        $summary = $sync->runSeason($season);
        $processed = $summary['fixtures'] + $summary['standings'] + $summary['teams'] + $summary['top_scorers'];

        if ($summary['errors'] !== []) {
            return $this->fail(implode("\n", $summary['errors']), null, 422);
        }

        return $this->ok(['processed' => $processed], __('Sync completed.'));
    }

    public function logs(Request $request): JsonResponse
    {
        $logs = ApiFootballSyncLog::query()
            ->when($request->filled('status'), fn ($q) => $q->where('status', $request->string('status')))
            ->latest('created_at')
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok(SyncLogResource::collection($logs));
    }

    /**
     * @return array{league: int, season: int}
     */
    protected function leagueSeason(Request $request): array
    {
        $data = $request->validate([
            'league' => ['required', 'integer'],
            'season' => ['required', 'integer'],
        ]);

        return ['league' => $data['league'], 'season' => $data['season']];
    }

    /**
     * @param  Closure():int  $task
     */
    protected function run(Closure $task): JsonResponse
    {
        try {
            return $this->ok(['processed' => $task()], __('Sync completed.'));
        } catch (ApiFootballException $e) {
            return $this->fail($e->getMessage(), null, $e->rateLimited ? 429 : 422);
        }
    }
}
