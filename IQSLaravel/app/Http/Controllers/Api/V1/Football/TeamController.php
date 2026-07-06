<?php

namespace App\Http\Controllers\Api\V1\Football;

use App\Models\Country;
use App\Models\Fixture;
use App\Models\League;
use App\Models\Standing;
use App\Models\Team;
use App\Support\Football\FootballShape;
use App\Support\Football\TeamSeasonStatistics;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class TeamController extends FootballController
{
    /**
     * GET /football/teams — mirrors API-Football `teams`.
     * Filters: id, name, league, season (YYYY), country, code, venue, search.
     */
    public function index(Request $request): JsonResponse
    {
        $teams = Team::query()
            ->where('is_active', true)
            ->with(['venue.country', 'country'])
            ->when($request->filled('id'), fn ($q) => $q->whereKey($request->integer('id')))
            ->when($request->filled('name'), fn ($q) => $this->whereNameLike($q, $request->string('name')->toString()))
            ->when($request->filled('league'), function ($q) use ($request) {
                $q->whereIn('id', $this->teamIdsForLeague(
                    $request->integer('league'),
                    $request->filled('season') ? $request->integer('season') : null,
                ));
            })
            ->when($request->filled('country'), function ($q) use ($request) {
                $country = $request->string('country')->toString();
                $q->where(fn ($w) => $w
                    ->where('country_name', 'like', "%{$country}%")
                    ->orWhereHas('country', fn ($c) => $this->whereNameLike($c, $country)));
            })
            ->when($request->filled('code'), fn ($q) => $q->where('short_code', strtoupper($request->string('code')->toString())))
            ->when($request->filled('venue'), fn ($q) => $q->where('venue_id', $request->integer('venue')))
            ->when($request->filled('search'), function ($q) use ($request) {
                $search = $request->string('search')->toString();
                $q->where(fn ($w) => $w
                    ->where('name_ar', 'like', "%{$search}%")
                    ->orWhere('name_en', 'like', "%{$search}%")
                    ->orWhere('country_name', 'like', "%{$search}%"));
            })
            ->orderBy('name_en')
            ->get();

        return $this->ok(
            $teams->map(fn (Team $team): array => FootballShape::team($team)),
            meta: ['results' => $teams->count()],
        );
    }

    /**
     * GET /football/teams/statistics — mirrors `teams/statistics`.
     * Required: league, season (YYYY), team. Optional: date (limit date).
     * Computed live from fixtures, events and lineups.
     */
    public function statistics(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'league' => ['required', 'integer'],
            'season' => ['required', 'integer'],
            'team' => ['required', 'integer'],
            'date' => ['nullable', 'date_format:Y-m-d'],
        ]);

        $league = League::query()->with('country')->find($validated['league']);
        $team = Team::query()->find($validated['team']);
        $season = $league !== null ? $this->resolveSeason($league, (int) $validated['season']) : null;

        if ($league === null || $team === null || $season === null) {
            return $this->fail(__('League, season or team not found.'), status: 404);
        }

        $until = isset($validated['date']) ? Carbon::parse($validated['date'])->endOfDay() : null;

        return $this->ok(TeamSeasonStatistics::build($team, $league, $season, $until));
    }

    /**
     * GET /football/teams/seasons — mirrors `teams/seasons`.
     */
    public function seasons(Request $request): JsonResponse
    {
        $request->validate(['team' => ['required', 'integer']]);

        $teamId = $request->integer('team');

        $fromFixtures = Fixture::query()
            ->where(fn ($q) => $q->where('home_team_id', $teamId)->orWhere('away_team_id', $teamId))
            ->whereNotNull('season_id')
            ->join('seasons', 'seasons.id', '=', 'fixtures.season_id')
            ->pluck('seasons.year');

        $fromStandings = Standing::query()
            ->where('team_id', $teamId)
            ->join('seasons', 'seasons.id', '=', 'standings.season_id')
            ->pluck('seasons.year');

        $years = $fromFixtures->merge($fromStandings)->unique()->sort()->values();

        return $this->ok($years, meta: ['results' => $years->count()]);
    }

    /**
     * GET /football/teams/countries — mirrors `teams/countries`.
     */
    public function countries(): JsonResponse
    {
        $countries = Country::query()
            ->whereHas('teams')
            ->orderBy('name_en')
            ->get();

        return $this->ok(
            $countries->map(fn (Country $country): array => FootballShape::country($country)),
            meta: ['results' => $countries->count()],
        );
    }

    /**
     * Teams participating in a league (via fixtures or standings), optionally
     * restricted to one season year.
     *
     * @return list<int>
     */
    private function teamIdsForLeague(int $leagueId, ?int $year): array
    {
        $seasonYear = fn ($q) => $q->when(
            $year !== null,
            fn ($w) => $w->whereHas('season', fn ($s) => $s->where('year', $year))
        );

        $fromFixtures = Fixture::query()
            ->where('league_id', $leagueId)
            ->tap($seasonYear)
            ->get(['home_team_id', 'away_team_id']);

        $fromStandings = Standing::query()
            ->where('league_id', $leagueId)
            ->when($year !== null, fn ($q) => $q->whereHas('season', fn ($s) => $s->where('year', $year)))
            ->pluck('team_id');

        return $fromFixtures->pluck('home_team_id')
            ->merge($fromFixtures->pluck('away_team_id'))
            ->merge($fromStandings)
            ->unique()
            ->values()
            ->all();
    }
}
