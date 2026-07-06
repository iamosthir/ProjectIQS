<?php

namespace App\Http\Controllers\Api\V1\Football;

use App\Models\League;
use App\Models\Standing;
use App\Support\Football\FootballShape;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StandingController extends FootballController
{
    /**
     * GET /football/standings — mirrors API-Football `standings`.
     * Filters: league, season (YYYY), team. At least league or team.
     */
    public function index(Request $request): JsonResponse
    {
        if (! $request->filled('league') && ! $request->filled('team')) {
            return $this->fail(__('At least one of league or team is required.'), status: 422);
        }

        $year = $request->filled('season') ? $request->integer('season') : null;

        $leagues = League::query()
            ->with('country')
            ->when($request->filled('league'), fn ($q) => $q->whereKey($request->integer('league')))
            ->when($request->filled('team'), fn ($q) => $q->whereHas(
                'standings', fn ($s) => $s->where('team_id', $request->integer('team'))
            ))
            ->get();

        $items = [];

        foreach ($leagues as $league) {
            $season = $this->resolveSeason($league, $year);

            if ($season === null) {
                continue;
            }

            $rows = Standing::query()
                ->where('league_id', $league->id)
                ->where('season_id', $season->id)
                ->when($request->filled('team'), fn ($q) => $q->where('team_id', $request->integer('team')))
                ->with('team')
                ->orderBy('group_label')
                ->orderBy('rank')
                ->get();

            if ($rows->isEmpty()) {
                continue;
            }

            $items[] = FootballShape::standings($league, $season, $rows);
        }

        return $this->ok($items, meta: ['results' => count($items)]);
    }
}
