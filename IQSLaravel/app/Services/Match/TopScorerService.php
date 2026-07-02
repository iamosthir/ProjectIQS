<?php

namespace App\Services\Match;

use App\Models\TopScorer;

/**
 * Maintains the ranked top-scorers list for a league/season. Called after any
 * scorer edit or when a Goal event is logged (§2.4).
 */
class TopScorerService
{
    /**
     * Re-sort the list by goals (desc) and rewrite each scorer's rank/order.
     */
    public function recomputeRanks(int $leagueId, ?int $seasonId): void
    {
        $scorers = TopScorer::query()
            ->where('league_id', $leagueId)
            ->when(
                $seasonId === null,
                fn ($q) => $q->whereNull('season_id'),
                fn ($q) => $q->where('season_id', $seasonId),
            )
            ->orderByDesc('goals')
            ->orderBy('id')
            ->get();

        $rank = 1;

        foreach ($scorers as $scorer) {
            $scorer->forceFill(['rank' => $rank, 'display_order' => $rank])->saveQuietly();
            $rank++;
        }
    }
}
