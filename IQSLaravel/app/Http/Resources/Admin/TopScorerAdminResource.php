<?php

namespace App\Http\Resources\Admin;

use App\Models\TopScorer;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin TopScorer
 */
class TopScorerAdminResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'source' => $this->source?->value,
            'league_id' => $this->league_id,
            'season_id' => $this->season_id,
            'player_id' => $this->player_id,
            'player_name' => $this->player_name,
            'player_photo_path' => $this->player_photo_path,
            'team_id' => $this->team_id,
            'team_name' => $this->team_name,
            'goals' => $this->goals,
            'assists' => $this->assists,
            'penalties' => $this->penalties,
            'rank' => $this->rank,
        ];
    }
}
