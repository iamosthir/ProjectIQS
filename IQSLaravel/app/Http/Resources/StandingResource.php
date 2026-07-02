<?php

namespace App\Http\Resources;

use App\Models\Standing;
use App\Support\Localize;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Standing
 */
class StandingResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'rank' => $this->rank,
            'team' => [
                'id' => $this->team_id,
                'name' => Localize::pick($this->team?->name_ar, $this->team?->name_en),
                'logo' => $this->team?->logo_path,
            ],
            'group' => $this->group_label !== '' ? $this->group_label : null,
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
