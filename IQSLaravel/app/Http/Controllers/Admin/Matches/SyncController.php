<?php

namespace App\Http\Controllers\Admin\Matches;

use App\Http\Controllers\Controller;
use App\Http\Resources\Admin\SyncLogResource;
use App\Models\ApiFootballSyncLog;
use App\Models\Fixture;
use App\Services\ApiFootball\ApiFootballException;
use App\Services\ApiFootball\FixtureDetailSync;
use App\Services\ApiFootball\FixtureSync;
use App\Services\ApiFootball\LeagueSync;
use App\Services\ApiFootball\StandingSync;
use App\Services\ApiFootball\TeamSync;
use App\Services\ApiFootball\TopScorerSync;
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
        return $this->run(fn () => $sync->sync($request->boolean('iraqi')));
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
