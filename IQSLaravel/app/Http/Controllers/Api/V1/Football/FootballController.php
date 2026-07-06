<?php

namespace App\Http\Controllers\Api\V1\Football;

use App\Http\Controllers\Controller;
use App\Models\League;
use App\Models\Season;
use Illuminate\Database\Eloquent\Builder;

/**
 * Shared helpers for the API-Football-mirror endpoints (/api/v1/football/*).
 * Filters follow the upstream query-parameter contract; `season` is always
 * the 4-digit year, resolved against the league's `seasons` rows.
 */
abstract class FootballController extends Controller
{
    /**
     * Resolve a season row for a league from a YYYY query value, falling back
     * to the league's current (or latest) season.
     */
    protected function resolveSeason(League $league, ?int $year): ?Season
    {
        if ($year !== null) {
            return $league->seasons()->where('year', $year)->first();
        }

        return $league->seasons()->where('is_current', true)->first()
            ?? $league->seasons()->orderByDesc('year')->first();
    }

    /**
     * Apply a bilingual name LIKE filter.
     *
     * @param  Builder<covariant \Illuminate\Database\Eloquent\Model>  $query
     */
    protected function whereNameLike(Builder $query, string $value): void
    {
        $query->where(fn ($q) => $q
            ->where('name_ar', 'like', "%{$value}%")
            ->orWhere('name_en', 'like', "%{$value}%"));
    }
}
