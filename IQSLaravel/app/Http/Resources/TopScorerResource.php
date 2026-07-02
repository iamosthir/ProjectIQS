<?php

namespace App\Http\Resources;

use App\Models\TopScorer;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin TopScorer
 */
class TopScorerResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'rank' => $this->rank,
            'player' => [
                'id' => $this->player_id,
                'name' => $this->player_name,
                'photo' => $this->player_photo_path,
            ],
            'team' => [
                'id' => $this->team_id,
                'name' => $this->team_name,
            ],
            'goals' => $this->goals,
            'assists' => $this->assists,
            'penalties' => $this->penalties,
        ];
    }
}
