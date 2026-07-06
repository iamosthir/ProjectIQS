<?php

namespace App\Http\Controllers\Api\V1\Football;

use App\Models\Trophy;
use App\Support\Football\FootballShape;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TrophyController extends FootballController
{
    /**
     * GET /football/trophies — mirrors API-Football `trophies`.
     * Filters: player, coach. At least one is required.
     */
    public function index(Request $request): JsonResponse
    {
        if (! $request->filled('player') && ! $request->filled('coach')) {
            return $this->fail(__('At least one of player or coach is required.'), status: 422);
        }

        $trophies = Trophy::query()
            ->when($request->filled('player'), fn ($q) => $q->where('player_id', $request->integer('player')))
            ->when($request->filled('coach'), fn ($q) => $q->where('coach_id', $request->integer('coach')))
            ->orderByDesc('season')
            ->get();

        return $this->ok(
            $trophies->map(fn (Trophy $trophy): array => FootballShape::trophy($trophy)),
            meta: ['results' => $trophies->count()],
        );
    }
}
