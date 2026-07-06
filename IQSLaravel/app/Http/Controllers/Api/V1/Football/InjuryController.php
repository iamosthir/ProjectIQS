<?php

namespace App\Http\Controllers\Api\V1\Football;

use App\Models\Injury;
use App\Support\Football\FootballShape;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class InjuryController extends FootballController
{
    /**
     * GET /football/injuries — mirrors API-Football `injuries`.
     * Filters: league (+season), season (YYYY), fixture, ids (fixture ids),
     * team, player, date. At least one is required.
     */
    public function index(Request $request): JsonResponse
    {
        if (! $request->hasAny(['league', 'fixture', 'ids', 'team', 'player', 'date'])) {
            return $this->fail(__('At least one parameter is required.'), status: 422);
        }

        $injuries = Injury::query()
            ->with(['player', 'team', 'league.country', 'season', 'fixture'])
            ->when($request->filled('league'), fn ($q) => $q->where('league_id', $request->integer('league')))
            ->when($request->filled('season'), fn ($q) => $q->whereHas(
                'season', fn ($s) => $s->where('year', $request->integer('season'))
            ))
            ->when($request->filled('fixture'), fn ($q) => $q->where('fixture_id', $request->integer('fixture')))
            ->when($request->filled('ids'), fn ($q) => $q->whereIn(
                'fixture_id',
                array_slice(array_filter(explode('-', $request->string('ids')->toString())), 0, 20),
            ))
            ->when($request->filled('team'), fn ($q) => $q->where('team_id', $request->integer('team')))
            ->when($request->filled('player'), fn ($q) => $q->where('player_id', $request->integer('player')))
            ->when($request->filled('date'), fn ($q) => $q->whereDate('date', $request->string('date')->toString()))
            ->orderByDesc('date')
            ->get();

        return $this->ok(
            $injuries->map(fn (Injury $injury): array => FootballShape::injury($injury)),
            meta: ['results' => $injuries->count()],
        );
    }
}
