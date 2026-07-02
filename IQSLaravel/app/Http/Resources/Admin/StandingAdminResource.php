<?php

namespace App\Http\Resources\Admin;

use App\Models\Standing;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Standing
 */
class StandingAdminResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'league_id' => $this->league_id,
            'season_id' => $this->season_id,
            'team_id' => $this->team_id,
            'team' => $this->whenLoaded('team', fn () => $this->team ? [
                'id' => $this->team->id,
                'name_ar' => $this->team->name_ar,
                'name_en' => $this->team->name_en,
                'logo' => $this->team->logo_path,
            ] : null),
            'group_label' => $this->group_label,
            'rank' => $this->rank,
            'points' => $this->points,
            'goals_diff' => $this->goals_diff,
            'played' => $this->played,
            'win' => $this->win,
            'draw' => $this->draw,
            'lose' => $this->lose,
            'goals_for' => $this->goals_for,
            'goals_against' => $this->goals_against,
            'form' => $this->form,
            'status' => $this->status,
            'description' => $this->description,
        ];
    }
}
