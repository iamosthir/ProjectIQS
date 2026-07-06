<?php

namespace App\Http\Controllers\Api\V1\Football;

use App\Models\Venue;
use App\Support\Football\FootballShape;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VenueController extends FootballController
{
    /**
     * GET /football/venues — mirrors API-Football `venues`.
     * Filters: id, name, city, country, search.
     */
    public function index(Request $request): JsonResponse
    {
        $venues = Venue::query()
            ->with('country')
            ->when($request->filled('id'), fn ($q) => $q->whereKey($request->integer('id')))
            ->when($request->filled('name'), fn ($q) => $this->whereNameLike($q, $request->string('name')->toString()))
            ->when($request->filled('city'), fn ($q) => $q->where('city', 'like', '%'.$request->string('city')->toString().'%'))
            ->when($request->filled('country'), function ($q) use ($request) {
                $country = $request->string('country')->toString();
                $q->where(fn ($w) => $w
                    ->where('country_name', 'like', "%{$country}%")
                    ->orWhereHas('country', fn ($c) => $this->whereNameLike($c, $country)));
            })
            ->when($request->filled('search'), function ($q) use ($request) {
                $search = $request->string('search')->toString();
                $q->where(fn ($w) => $w
                    ->where('name_ar', 'like', "%{$search}%")
                    ->orWhere('name_en', 'like', "%{$search}%")
                    ->orWhere('city', 'like', "%{$search}%")
                    ->orWhere('country_name', 'like', "%{$search}%"));
            })
            ->orderBy('name_en')
            ->get();

        return $this->ok(
            $venues->map(fn (Venue $venue): array => FootballShape::venue($venue)),
            meta: ['results' => $venues->count()],
        );
    }
}
