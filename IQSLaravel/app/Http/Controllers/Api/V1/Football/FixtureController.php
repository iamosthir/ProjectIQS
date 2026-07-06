<?php

namespace App\Http\Controllers\Api\V1\Football;

use App\Models\Fixture;
use App\Models\FixtureEvent;
use App\Models\FixtureLineup;
use App\Models\FixturePlayerStatistic;
use App\Models\FixtureStatistic;
use App\Support\Enums\FixtureStatusGroup;
use App\Support\Football\FootballShape;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FixtureController extends FootballController
{
    /**
     * GET /football/fixtures — mirrors API-Football `fixtures`.
     * Filters: id, ids (id-id-…, max 20), live (all|leagueId-leagueId),
     * date, league, season (YYYY), team, last, next, from, to, round,
     * status (SHORT or SHORT-SHORT-…), venue.
     */
    public function index(Request $request): JsonResponse
    {
        $query = $this->baseQuery();
        $bounded = false;

        if ($request->filled('id')) {
            $query->whereKey($request->integer('id'));
            $bounded = true;
        }

        if ($request->filled('ids')) {
            $ids = array_slice(array_filter(explode('-', $request->string('ids')->toString())), 0, 20);
            $query->whereIn('id', $ids);
            $bounded = true;
        }

        if ($request->filled('live')) {
            $query->where('status_group', FixtureStatusGroup::Live);
            $live = $request->string('live')->toString();
            if ($live !== 'all') {
                $query->whereIn('league_id', array_filter(explode('-', $live)));
            }
            $bounded = true;
        }

        $this->applyCommonFilters($query, $request);

        if ($request->filled('last')) {
            $query->where('match_datetime', '<=', now())
                ->orderByDesc('match_datetime')
                ->limit(min(99, max(1, $request->integer('last'))));
            $bounded = true;
        } elseif ($request->filled('next')) {
            $query->where('match_datetime', '>=', now())
                ->orderBy('match_datetime')
                ->limit(min(99, max(1, $request->integer('next'))));
            $bounded = true;
        } else {
            $query->orderBy('match_datetime');
        }

        if ($bounded) {
            $fixtures = $query->get();

            return $this->ok(
                $fixtures->map(fn (Fixture $fixture): array => FootballShape::fixture($fixture)),
                meta: ['results' => $fixtures->count()],
            );
        }

        $fixtures = $query->paginate($this->perPage($request))->appends($request->query());

        return $this->ok($fixtures->through(fn (Fixture $fixture): array => FootballShape::fixture($fixture)));
    }

    /**
     * GET /football/fixtures/rounds — mirrors `fixtures/rounds`.
     * Required: league, season (YYYY). Optional: current, dates.
     */
    public function rounds(Request $request): JsonResponse
    {
        $request->validate([
            'league' => ['required', 'integer'],
            'season' => ['required', 'integer'],
        ]);

        $rounds = Fixture::query()
            ->where('league_id', $request->integer('league'))
            ->whereHas('season', fn ($s) => $s->where('year', $request->integer('season')))
            ->whereNotNull('round')
            ->orderBy('match_datetime')
            ->get(['round', 'match_datetime'])
            ->groupBy('round');

        if ($request->boolean('current')) {
            // The round of the next upcoming fixture, or the last one played.
            $current = $rounds
                ->sortBy(fn ($group) => $group->min('match_datetime'))
                ->filter(fn ($group) => $group->max('match_datetime') >= now())
                ->keys()
                ->first() ?? $rounds->sortBy(fn ($group) => $group->min('match_datetime'))->keys()->last();

            $rounds = $current !== null ? $rounds->only([$current]) : collect();
        }

        $items = $rounds
            ->sortBy(fn ($group) => $group->min('match_datetime'))
            ->keys()
            ->values();

        if ($request->boolean('dates')) {
            $items = $items->map(fn (string $round): array => [
                'round' => $round,
                'dates' => $rounds[$round]->pluck('match_datetime')
                    ->map(fn ($dt) => $dt?->toDateString())
                    ->filter()
                    ->unique()
                    ->values()
                    ->all(),
            ]);
        }

        return $this->ok($items, meta: ['results' => $items->count()]);
    }

    /**
     * GET /football/fixtures/headtohead — mirrors `fixtures/headtohead`.
     * Required: h2h (teamId-teamId). Optional: the common fixture filters.
     */
    public function headToHead(Request $request): JsonResponse
    {
        $request->validate(['h2h' => ['required', 'regex:/^\d+-\d+$/']]);

        [$teamA, $teamB] = array_map('intval', explode('-', $request->string('h2h')->toString()));

        $query = $this->baseQuery()
            ->where(fn ($q) => $q
                ->where(fn ($w) => $w->where('home_team_id', $teamA)->where('away_team_id', $teamB))
                ->orWhere(fn ($w) => $w->where('home_team_id', $teamB)->where('away_team_id', $teamA)));

        $this->applyCommonFilters($query, $request);

        if ($request->filled('last')) {
            $query->where('match_datetime', '<=', now())
                ->orderByDesc('match_datetime')
                ->limit(min(99, max(1, $request->integer('last'))));
        } elseif ($request->filled('next')) {
            $query->where('match_datetime', '>=', now())
                ->orderBy('match_datetime')
                ->limit(min(99, max(1, $request->integer('next'))));
        } else {
            $query->orderBy('match_datetime');
        }

        $fixtures = $query->get();

        return $this->ok(
            $fixtures->map(fn (Fixture $fixture): array => FootballShape::fixture($fixture)),
            meta: ['results' => $fixtures->count()],
        );
    }

    /**
     * GET /football/fixtures/statistics — mirrors `fixtures/statistics`.
     * Required: fixture. Optional: team, type.
     */
    public function statistics(Request $request): JsonResponse
    {
        $request->validate(['fixture' => ['required', 'integer']]);

        $rows = FixtureStatistic::query()
            ->where('fixture_id', $request->integer('fixture'))
            ->when($request->filled('team'), fn ($q) => $q->where('team_id', $request->integer('team')))
            ->when($request->filled('type'), fn ($q) => $q->where('type', $request->string('type')->toString()))
            ->with('team')
            ->orderBy('team_id')
            ->orderBy('display_order')
            ->get();

        $items = $rows->groupBy('team_id')->map(fn ($group) => [
            'team' => FootballShape::teamRef($group->first()->team),
            'statistics' => $group->map(fn (FixtureStatistic $row): array => [
                'type' => $row->type,
                'value' => $row->value,
            ])->values()->all(),
        ])->values();

        return $this->ok($items, meta: ['results' => $items->count()]);
    }

    /**
     * GET /football/fixtures/events — mirrors `fixtures/events`.
     * Required: fixture. Optional: team, player, type.
     */
    public function events(Request $request): JsonResponse
    {
        $request->validate(['fixture' => ['required', 'integer']]);

        $events = FixtureEvent::query()
            ->where('fixture_id', $request->integer('fixture'))
            ->when($request->filled('team'), fn ($q) => $q->where('team_id', $request->integer('team')))
            ->when($request->filled('player'), function ($q) use ($request) {
                $playerId = $request->integer('player');
                $q->where(fn ($w) => $w->where('player_id', $playerId)->orWhere('assist_player_id', $playerId));
            })
            ->when($request->filled('type'), fn ($q) => $q->where('type', strtolower($request->string('type')->toString())))
            ->with(['team', 'player', 'assistPlayer'])
            ->orderBy('elapsed')
            ->orderBy('display_order')
            ->get();

        return $this->ok(
            $events->map(fn (FixtureEvent $event): array => FootballShape::event($event)),
            meta: ['results' => $events->count()],
        );
    }

    /**
     * GET /football/fixtures/lineups — mirrors `fixtures/lineups`.
     * Required: fixture. Optional: team.
     */
    public function lineups(Request $request): JsonResponse
    {
        $request->validate(['fixture' => ['required', 'integer']]);

        $lineups = FixtureLineup::query()
            ->where('fixture_id', $request->integer('fixture'))
            ->when($request->filled('team'), fn ($q) => $q->where('team_id', $request->integer('team')))
            ->with(['team', 'coach', 'players.player'])
            ->get();

        return $this->ok(
            $lineups->map(fn (FixtureLineup $lineup): array => FootballShape::lineup($lineup)),
            meta: ['results' => $lineups->count()],
        );
    }

    /**
     * GET /football/fixtures/players — mirrors `fixtures/players`.
     * Required: fixture. Optional: team.
     */
    public function players(Request $request): JsonResponse
    {
        $request->validate(['fixture' => ['required', 'integer']]);

        $rows = FixturePlayerStatistic::query()
            ->where('fixture_id', $request->integer('fixture'))
            ->when($request->filled('team'), fn ($q) => $q->where('team_id', $request->integer('team')))
            ->with(['team', 'player'])
            ->get();

        $items = $rows->groupBy('team_id')->map(fn ($group) => [
            'team' => FootballShape::teamRef($group->first()->team) + [
                'update' => $group->max('updated_at')?->toIso8601String(),
            ],
            'players' => $group->map(
                fn (FixturePlayerStatistic $row): array => FootballShape::fixturePlayerStatistics($row)
            )->values()->all(),
        ])->values();

        return $this->ok($items, meta: ['results' => $items->count()]);
    }

    /**
     * @return Builder<Fixture>
     */
    private function baseQuery(): Builder
    {
        return Fixture::query()
            ->with(['league.country', 'season', 'homeTeam', 'awayTeam', 'venue']);
    }

    /**
     * Filters shared by `fixtures` and `fixtures/headtohead`.
     *
     * @param  Builder<Fixture>  $query
     */
    private function applyCommonFilters(Builder $query, Request $request): void
    {
        $query
            ->when($request->filled('date'), fn ($q) => $q->whereDate('match_datetime', $request->string('date')->toString()))
            ->when($request->filled('league'), fn ($q) => $q->where('league_id', $request->integer('league')))
            ->when($request->filled('season'), fn ($q) => $q->whereHas(
                'season', fn ($s) => $s->where('year', $request->integer('season'))
            ))
            ->when($request->filled('team'), function ($q) use ($request) {
                $teamId = $request->integer('team');
                $q->where(fn ($w) => $w->where('home_team_id', $teamId)->orWhere('away_team_id', $teamId));
            })
            ->when($request->filled('from'), fn ($q) => $q->whereDate('match_datetime', '>=', $request->string('from')->toString()))
            ->when($request->filled('to'), fn ($q) => $q->whereDate('match_datetime', '<=', $request->string('to')->toString()))
            ->when($request->filled('round'), fn ($q) => $q->where('round', $request->string('round')->toString()))
            ->when($request->filled('status'), function ($q) use ($request) {
                $statuses = array_map('strtoupper', array_filter(explode('-', $request->string('status')->toString())));
                $q->whereIn('status_short', $statuses);
            })
            ->when($request->filled('venue'), fn ($q) => $q->where('venue_id', $request->integer('venue')));
    }
}
