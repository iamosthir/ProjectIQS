<?php

namespace App\Http\Resources;

use App\Models\Fixture;
use App\Models\Team;
use App\Support\Enums\MatchWinner;
use App\Support\Localize;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * The canonical fixture shape — identical whether the row came from
 * API-Football or manual entry (§0.9 / §2.5).
 *
 * @mixin Fixture
 */
class FixtureResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'league' => [
                'id' => $this->league_id,
                'name' => Localize::pick($this->league?->name_ar, $this->league?->name_en),
                'logo' => $this->league?->logo_path,
                'round' => $this->round,
            ],
            'status' => [
                'short' => $this->status_short,
                'group' => $this->status_group?->value,
                'long' => $this->status_long,
                'elapsed' => $this->elapsed,
            ],
            'datetime' => $this->match_datetime?->toIso8601String(),
            'venue' => $this->venue ? [
                'id' => $this->venue->id,
                'name' => Localize::pick($this->venue->name_ar, $this->venue->name_en),
                'city' => $this->venue->city,
            ] : null,
            'home' => $this->side($this->homeTeam, $this->home_goals, MatchWinner::Home),
            'away' => $this->side($this->awayTeam, $this->away_goals, MatchWinner::Away),
            'score' => [
                'halftime' => ['home' => $this->home_ht, 'away' => $this->away_ht],
                'fulltime' => ['home' => $this->home_ft, 'away' => $this->away_ft],
                'extratime' => ['home' => $this->home_et, 'away' => $this->away_et],
                'penalty' => ['home' => $this->home_pen, 'away' => $this->away_pen],
            ],
            'is_featured' => $this->is_featured,
            'has' => [
                'events' => $this->has_events,
                'lineups' => $this->has_lineups,
                'statistics' => $this->has_statistics,
            ],
            'social' => [
                'likes' => $this->likes_count,
                'comments' => $this->comments_count,
                'shares' => $this->shares_count,
            ],
        ];
    }

    /**
     * @return array<string, mixed>
     */
    protected function side(?Team $team, ?int $goals, MatchWinner $side): array
    {
        return [
            'id' => $team?->id,
            'name' => Localize::pick($team?->name_ar, $team?->name_en),
            'logo' => $team?->logo_path,
            'goals' => $goals,
            'winner' => $this->winner === $side,
        ];
    }
}
