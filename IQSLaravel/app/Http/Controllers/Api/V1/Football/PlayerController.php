<?php

namespace App\Http\Controllers\Api\V1\Football;

use App\Models\League;
use App\Models\Player;
use App\Models\PlayerStatistic;
use App\Models\Team;
use App\Support\Football\FootballShape;
use App\Support\Localize;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PlayerController extends FootballController
{
    /**
     * GET /football/players/seasons — mirrors `players/seasons`.
     */
    public function seasons(): JsonResponse
    {
        $years = PlayerStatistic::query()
            ->join('seasons', 'seasons.id', '=', 'player_statistics.season_id')
            ->distinct()
            ->orderBy('seasons.year')
            ->pluck('seasons.year');

        return $this->ok($years, meta: ['results' => $years->count()]);
    }

    /**
     * GET /football/players/profiles — mirrors `players/profiles`.
     * Filters: player (id), search. Paginated.
     */
    public function profiles(Request $request): JsonResponse
    {
        $players = Player::query()
            ->when($request->filled('player'), fn ($q) => $q->whereKey($request->integer('player')))
            ->when($request->filled('search'), function ($q) use ($request) {
                $search = $request->string('search')->toString();
                $q->where(fn ($w) => $w
                    ->where('name_ar', 'like', "%{$search}%")
                    ->orWhere('name_en', 'like', "%{$search}%")
                    ->orWhere('lastname', 'like', "%{$search}%"));
            })
            ->orderBy('name_en')
            ->paginate($this->perPage($request, 50))
            ->appends($request->query());

        return $this->ok($players->through(fn (Player $player): array => [
            'player' => FootballShape::playerProfile($player),
        ]));
    }

    /**
     * GET /football/players — mirrors `players` (profile + season statistics).
     * Filters: id, team, league, season (YYYY), search. At least one of
     * id, team, league or search is required.
     */
    public function index(Request $request): JsonResponse
    {
        if (! $request->hasAny(['id', 'team', 'league', 'search'])) {
            return $this->fail(__('At least one of id, team, league or search is required.'), status: 422);
        }

        $statsScope = function ($q) use ($request): void {
            $q->when($request->filled('team'), fn ($s) => $s->where('team_id', $request->integer('team')))
                ->when($request->filled('league'), fn ($s) => $s->where('league_id', $request->integer('league')))
                ->when($request->filled('season'), fn ($s) => $s->whereHas(
                    'season', fn ($y) => $y->where('year', $request->integer('season'))
                ));
        };

        $players = Player::query()
            ->when($request->filled('id'), fn ($q) => $q->whereKey($request->integer('id')))
            ->when($request->filled('search'), fn ($q) => $this->whereNameLike($q, $request->string('search')->toString()))
            ->when(
                $request->hasAny(['team', 'league']) || ($request->filled('season') && ! $request->filled('id')),
                fn ($q) => $q->whereHas('statistics', $statsScope)
            )
            ->with(['statistics' => function ($q) use ($statsScope) {
                $statsScope($q);
                $q->with(['team', 'league.country', 'season']);
            }])
            ->orderBy('name_en')
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok($players->through(
            fn (Player $player): array => FootballShape::playerWithStatistics($player, $player->statistics)
        ));
    }

    /**
     * GET /football/players/squads — mirrors `players/squads`.
     * Filters: team OR player (at least one).
     */
    public function squads(Request $request): JsonResponse
    {
        if (! $request->filled('team') && ! $request->filled('player')) {
            return $this->fail(__('At least one of team or player is required.'), status: 422);
        }

        $squadEntry = function (Team $team, $players): array {
            return [
                'team' => FootballShape::teamRef($team),
                'players' => collect($players)->map(fn (Player $player): array => [
                    'id' => $player->id,
                    'name' => Localize::pick($player->name_ar, $player->name_en),
                    'age' => $player->date_of_birth?->age,
                    'number' => $player->pivot->number ?? $player->number,
                    'position' => $player->pivot->position ?? $player->position,
                    'photo' => $player->photo_path,
                ])->values()->all(),
            ];
        };

        if ($request->filled('team')) {
            $team = Team::query()->find($request->integer('team'));

            if ($team === null) {
                return $this->fail(__('Team not found.'), status: 404);
            }

            $players = $team->players()->wherePivot('is_active', true)->get();

            return $this->ok([$squadEntry($team, $players)], meta: ['results' => 1]);
        }

        $player = Player::query()->find($request->integer('player'));

        if ($player === null) {
            return $this->fail(__('Player not found.'), status: 404);
        }

        $items = $player->teams()->wherePivot('is_active', true)->get()
            ->map(function (Team $team) use ($player, $squadEntry): array {
                $member = clone $player;
                $member->setRelation('pivot', $team->pivot);

                return $squadEntry($team, [$member]);
            })
            ->values();

        return $this->ok($items, meta: ['results' => $items->count()]);
    }

    /**
     * GET /football/players/teams — mirrors `players/teams`
     * (teams + season years across the player's career).
     */
    public function teams(Request $request): JsonResponse
    {
        $request->validate(['player' => ['required', 'integer']]);

        $rows = PlayerStatistic::query()
            ->where('player_id', $request->integer('player'))
            ->with(['team', 'season'])
            ->get()
            ->filter(fn (PlayerStatistic $row) => $row->team !== null);

        $items = $rows->groupBy('team_id')->map(fn ($group) => [
            'team' => FootballShape::teamRef($group->first()->team),
            'seasons' => $group->pluck('season.year')->filter()->unique()->sortDesc()->values()->all(),
        ])->values();

        return $this->ok($items, meta: ['results' => $items->count()]);
    }

    /**
     * GET /football/players/topscorers — mirrors `players/topscorers`.
     */
    public function topScorers(Request $request): JsonResponse
    {
        return $this->topBy($request, 'goals_total', ['goals_assists' => 'desc', 'appearances' => 'asc']);
    }

    /**
     * GET /football/players/topassists — mirrors `players/topassists`.
     */
    public function topAssists(Request $request): JsonResponse
    {
        return $this->topBy($request, 'goals_assists', ['goals_total' => 'desc', 'appearances' => 'asc']);
    }

    /**
     * GET /football/players/topyellowcards — mirrors `players/topyellowcards`.
     */
    public function topYellowCards(Request $request): JsonResponse
    {
        return $this->topBy($request, 'cards_yellow', ['cards_red' => 'desc']);
    }

    /**
     * GET /football/players/topredcards — mirrors `players/topredcards`.
     */
    public function topRedCards(Request $request): JsonResponse
    {
        return $this->topBy($request, 'cards_red', ['cards_yellow' => 'desc']);
    }

    /**
     * Shared "top 20 by metric for a league season" ranking over
     * player_statistics — the same derivation the upstream API documents.
     *
     * @param  array<string, string>  $tieBreakers
     */
    private function topBy(Request $request, string $metric, array $tieBreakers = []): JsonResponse
    {
        $request->validate(['league' => ['required', 'integer']]);

        $league = League::query()->find($request->integer('league'));

        if ($league === null) {
            return $this->fail(__('League not found.'), status: 404);
        }

        $season = $this->resolveSeason($league, $request->filled('season') ? $request->integer('season') : null);

        if ($season === null) {
            return $this->ok([], meta: ['results' => 0]);
        }

        $rows = PlayerStatistic::query()
            ->where('league_id', $league->id)
            ->where('season_id', $season->id)
            ->whereNotNull($metric)
            ->where($metric, '>', 0)
            ->orderByDesc($metric)
            ->when(true, function ($q) use ($tieBreakers) {
                foreach ($tieBreakers as $column => $direction) {
                    $q->orderBy($column, $direction);
                }
            })
            ->with(['player', 'team', 'league.country', 'season'])
            ->limit(20)
            ->get()
            ->filter(fn (PlayerStatistic $row) => $row->player !== null);

        return $this->ok(
            $rows->map(fn (PlayerStatistic $row): array => FootballShape::playerWithStatistics(
                $row->player, collect([$row]),
            ))->values(),
            meta: ['results' => $rows->count()],
        );
    }
}
