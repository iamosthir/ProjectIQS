<?php

namespace App\Http\Controllers\Api\V1\Football;

use App\Models\Coach;
use App\Support\Football\FootballShape;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CoachController extends FootballController
{
    /**
     * GET /football/coachs — mirrors API-Football `coachs`.
     * Filters: id, team, search. At least one is required.
     */
    public function index(Request $request): JsonResponse
    {
        if (! $request->filled('id') && ! $request->filled('team') && ! $request->filled('search')) {
            return $this->fail(__('At least one of id, team or search is required.'), status: 422);
        }

        $coaches = Coach::query()
            ->with(['team', 'careers.team'])
            ->when($request->filled('id'), fn ($q) => $q->whereKey($request->integer('id')))
            ->when($request->filled('team'), fn ($q) => $q->where('team_id', $request->integer('team')))
            ->when($request->filled('search'), fn ($q) => $this->whereNameLike($q, $request->string('search')->toString()))
            ->orderBy('name_en')
            ->get();

        return $this->ok(
            $coaches->map(fn (Coach $coach): array => FootballShape::coach($coach)),
            meta: ['results' => $coaches->count()],
        );
    }
}
