<?php

namespace App\Http\Controllers\Api\V1\Football;

use App\Models\Country;
use App\Support\Football\FootballShape;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CountryController extends FootballController
{
    /**
     * GET /football/countries — mirrors API-Football `countries`.
     * Filters: name, code, search.
     */
    public function index(Request $request): JsonResponse
    {
        $countries = Country::query()
            ->where('is_active', true)
            ->when($request->filled('name'), fn ($q) => $this->whereNameLike($q, $request->string('name')->toString()))
            ->when($request->filled('code'), fn ($q) => $q->where('code', strtoupper($request->string('code')->toString())))
            ->when($request->filled('search'), fn ($q) => $this->whereNameLike($q, $request->string('search')->toString()))
            ->orderBy('display_order')
            ->orderBy('name_en')
            ->get();

        return $this->ok(
            $countries->map(fn (Country $country): array => FootballShape::country($country)),
            meta: ['results' => $countries->count()],
        );
    }
}
