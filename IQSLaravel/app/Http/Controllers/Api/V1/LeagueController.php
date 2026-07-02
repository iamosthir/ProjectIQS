<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\FixtureResource;
use App\Http\Resources\LeagueResource;
use App\Http\Resources\StandingResource;
use App\Http\Resources\TopScorerResource;
use App\Models\Fixture;
use App\Models\League;
use App\Models\Season;
use App\Models\Standing;
use App\Models\TopScorer;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LeagueController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $leagues = League::query()
            ->where('is_active', true)
            ->when($request->filled('is_iraqi'), fn ($q) => $q->where('is_iraqi', $request->boolean('is_iraqi')))
            ->with('currentSeason')
            ->orderBy('tier')
            ->orderBy('display_order')
            ->get();

        return $this->ok(LeagueResource::collection($leagues));
    }

    public function show(League $league): JsonResponse
    {
        return $this->ok(new LeagueResource($league->load('currentSeason')));
    }

    public function standings(Request $request, League $league): JsonResponse
    {
        $seasonId = $this->resolveSeasonId($request, $league);

        $standings = Standing::query()
            ->where('league_id', $league->id)
            ->when($seasonId !== null, fn ($q) => $q->where('season_id', $seasonId))
            ->with('team')
            ->orderBy('group_label')
            ->orderBy('rank')
            ->get();

        return $this->ok(StandingResource::collection($standings));
    }

    public function fixtures(Request $request, League $league): JsonResponse
    {
        $fixtures = Fixture::query()
            ->where('league_id', $league->id)
            ->when($request->filled('status_group'), fn ($q) => $q->where('status_group', $request->string('status_group')))
            ->when($request->filled('date'), fn ($q) => $q->whereDate('match_datetime', $request->date('date')))
            ->when($request->filled('round'), fn ($q) => $q->where('round', $request->string('round')))
            ->with(['league', 'homeTeam', 'awayTeam', 'venue'])
            ->orderBy('match_datetime')
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok(FixtureResource::collection($fixtures));
    }

    public function topScorers(Request $request, League $league): JsonResponse
    {
        $seasonId = $this->resolveSeasonId($request, $league);

        $scorers = TopScorer::query()
            ->where('league_id', $league->id)
            ->when($seasonId !== null, fn ($q) => $q->where('season_id', $seasonId))
            ->orderByRaw('rank IS NULL, rank')
            ->orderByDesc('goals')
            ->get();

        return $this->ok(TopScorerResource::collection($scorers));
    }

    protected function resolveSeasonId(Request $request, League $league): ?int
    {
        if ($request->filled('season')) {
            return Season::query()
                ->where('league_id', $league->id)
                ->where('year', $request->integer('season'))
                ->value('id');
        }

        return $league->currentSeason?->id
            ?? Season::query()->where('league_id', $league->id)->orderByDesc('year')->value('id');
    }
}
