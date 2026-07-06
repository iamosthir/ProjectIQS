<?php

namespace App\Http\Controllers\Api\V1\Football;

use App\Models\Sidelined;
use App\Support\Football\FootballShape;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SidelinedController extends FootballController
{
    /**
     * GET /football/sidelined — mirrors API-Football `sidelined`.
     * Filters: player, coach. At least one is required.
     */
    public function index(Request $request): JsonResponse
    {
        if (! $request->filled('player') && ! $request->filled('coach')) {
            return $this->fail(__('At least one of player or coach is required.'), status: 422);
        }

        $sidelined = Sidelined::query()
            ->when($request->filled('player'), fn ($q) => $q->where('player_id', $request->integer('player')))
            ->when($request->filled('coach'), fn ($q) => $q->where('coach_id', $request->integer('coach')))
            ->orderByDesc('start_date')
            ->get();

        return $this->ok(
            $sidelined->map(fn (Sidelined $spell): array => FootballShape::sidelined($spell)),
            meta: ['results' => $sidelined->count()],
        );
    }
}
