<?php

namespace App\Http\Controllers\Api\V1\Football;

use App\Models\Transfer;
use App\Support\Football\FootballShape;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TransferController extends FootballController
{
    /**
     * GET /football/transfers — mirrors API-Football `transfers`.
     * Filters: player, team. At least one is required.
     */
    public function index(Request $request): JsonResponse
    {
        if (! $request->filled('player') && ! $request->filled('team')) {
            return $this->fail(__('At least one of player or team is required.'), status: 422);
        }

        $transfers = Transfer::query()
            ->with(['player', 'teamIn', 'teamOut'])
            ->when($request->filled('player'), fn ($q) => $q->where('player_id', $request->integer('player')))
            ->when($request->filled('team'), function ($q) use ($request) {
                $teamId = $request->integer('team');
                $q->where(fn ($w) => $w->where('team_in_id', $teamId)->orWhere('team_out_id', $teamId));
            })
            ->get();

        $items = $transfers
            ->filter(fn (Transfer $transfer) => $transfer->player !== null)
            ->groupBy('player_id')
            ->map(fn ($group) => FootballShape::transfers($group->first()->player, $group))
            ->values();

        return $this->ok($items, meta: ['results' => $items->count()]);
    }
}
