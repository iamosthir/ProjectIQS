<?php

namespace App\Http\Resources\Admin;

use App\Models\Fixture;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Fixture
 */
class FixtureAdminResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'source' => $this->source?->value,
            'external_id' => $this->external_id,
            'league_id' => $this->league_id,
            'season_id' => $this->season_id,
            'round' => $this->round,
            'home_team_id' => $this->home_team_id,
            'away_team_id' => $this->away_team_id,
            'venue_id' => $this->venue_id,
            'home_team' => $this->whenLoaded('homeTeam', fn () => $this->teamLabel($this->homeTeam)),
            'away_team' => $this->whenLoaded('awayTeam', fn () => $this->teamLabel($this->awayTeam)),
            'league' => $this->whenLoaded('league', fn () => $this->league ? [
                'id' => $this->league->id,
                'name' => $this->league->name_en,
            ] : null),
            'officials' => [
                'referee' => $this->referee,
                'assistant_1' => $this->referee_assistant_1,
                'assistant_2' => $this->referee_assistant_2,
                'fourth_official' => $this->referee_fourth_official,
                'supervisor' => $this->supervisor,
            ],
            'match_datetime' => $this->match_datetime?->toIso8601String(),
            'timezone' => $this->timezone,
            'status_short' => $this->status_short,
            'status_long' => $this->status_long,
            'status_group' => $this->status_group?->value,
            'elapsed' => $this->elapsed,
            'score' => [
                'home_goals' => $this->home_goals,
                'away_goals' => $this->away_goals,
                'home_ht' => $this->home_ht,
                'away_ht' => $this->away_ht,
                'home_ft' => $this->home_ft,
                'away_ft' => $this->away_ft,
                'home_et' => $this->home_et,
                'away_et' => $this->away_et,
                'home_pen' => $this->home_pen,
                'away_pen' => $this->away_pen,
            ],
            'winner' => $this->winner?->value,
            'is_featured' => $this->is_featured,
            'is_locked' => $this->is_locked,
            'has' => [
                'events' => $this->has_events,
                'lineups' => $this->has_lineups,
                'statistics' => $this->has_statistics,
            ],
            'counters' => [
                'likes' => $this->likes_count,
                'comments' => $this->comments_count,
                'shares' => $this->shares_count,
                'predictions' => $this->predictions_count,
            ],
            'predictions_settled' => $this->predictions_settled,
        ];
    }

    /**
     * @return array<string, mixed>|null
     */
    protected function teamLabel(?\App\Models\Team $team): ?array
    {
        return $team ? [
            'id' => $team->id,
            'name_ar' => $team->name_ar,
            'name_en' => $team->name_en,
            'logo' => $team->logo_path,
        ] : null;
    }
}
