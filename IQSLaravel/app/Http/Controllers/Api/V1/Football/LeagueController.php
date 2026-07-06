<?php

namespace App\Http\Controllers\Api\V1\Football;

use App\Models\League;
use App\Models\Season;
use App\Support\Football\FootballShape;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LeagueController extends FootballController
{
    /**
     * GET /football/leagues — mirrors API-Football `leagues`.
     * Filters: id, name, country, code, season (YYYY), team, type,
     * current, search, last.
     */
    public function index(Request $request): JsonResponse
    {
        $leagues = League::query()
            ->where('is_active', true)
            ->with(['country', 'seasons'])
            ->when($request->filled('id'), fn ($q) => $q->whereKey($request->integer('id')))
            ->when($request->filled('name'), fn ($q) => $this->whereNameLike($q, $request->string('name')->toString()))
            ->when($request->filled('country'), function ($q) use ($request) {
                $country = $request->string('country')->toString();
                $q->where(fn ($w) => $w
                    ->where('country_name', 'like', "%{$country}%")
                    ->orWhereHas('country', fn ($c) => $this->whereNameLike($c, $country)));
            })
            ->when($request->filled('code'), function ($q) use ($request) {
                $code = strtoupper($request->string('code')->toString());
                $q->where(fn ($w) => $w
                    ->where('country_code', $code)
                    ->orWhereHas('country', fn ($c) => $c->where('code', $code)));
            })
            ->when($request->filled('season'), fn ($q) => $q->whereHas(
                'seasons', fn ($s) => $s->where('year', $request->integer('season'))
            ))
            ->when($request->filled('team'), function ($q) use ($request) {
                $teamId = $request->integer('team');
                $q->whereHas('fixtures', fn ($f) => $f
                    ->where(fn ($w) => $w->where('home_team_id', $teamId)->orWhere('away_team_id', $teamId)));
            })
            ->when($request->filled('type'), fn ($q) => $q->where('type', strtolower($request->string('type')->toString())))
            ->when($request->filled('current'), fn ($q) => $q->whereHas(
                'seasons', fn ($s) => $s->where('is_current', $request->boolean('current'))
            ))
            ->when($request->filled('search'), function ($q) use ($request) {
                $search = $request->string('search')->toString();
                $q->where(fn ($w) => $w
                    ->where('name_ar', 'like', "%{$search}%")
                    ->orWhere('name_en', 'like', "%{$search}%")
                    ->orWhere('country_name', 'like', "%{$search}%")
                    ->orWhereHas('country', fn ($c) => $this->whereNameLike($c, $search)));
            })
            ->when(
                $request->filled('last'),
                fn ($q) => $q->orderByDesc('created_at')->limit(min(99, $request->integer('last'))),
                fn ($q) => $q->orderBy('tier')->orderBy('display_order'),
            )
            ->get();

        return $this->ok(
            $leagues->map(fn (League $league): array => FootballShape::league($league))->values(),
            meta: ['results' => $leagues->count()],
        );
    }

    /**
     * GET /football/leagues/seasons — mirrors `leagues/seasons`
     * (the list of available 4-digit season years).
     */
    public function seasons(): JsonResponse
    {
        $years = Season::query()
            ->distinct()
            ->orderBy('year')
            ->pluck('year');

        return $this->ok($years, meta: ['results' => $years->count()]);
    }
}
