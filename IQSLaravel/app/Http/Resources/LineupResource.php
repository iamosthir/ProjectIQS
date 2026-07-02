<?php

namespace App\Http\Resources;

use App\Models\FixtureLineup;
use App\Models\FixtureLineupPlayer;
use App\Support\Localize;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin FixtureLineup
 */
class LineupResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'team' => [
                'id' => $this->team_id,
                'name' => Localize::pick($this->team?->name_ar, $this->team?->name_en),
                'logo' => $this->team?->logo_path,
            ],
            'formation' => $this->formation,
            'coach' => [
                'name' => $this->coach_name ?: ($this->coach ? Localize::pick($this->coach->name_ar, $this->coach->name_en) : null),
                'photo' => $this->coach_photo,
            ],
            'startxi' => $this->players->where('is_starter', true)->map(fn ($p) => $this->playerRow($p))->values(),
            'substitutes' => $this->players->where('is_starter', false)->map(fn ($p) => $this->playerRow($p))->values(),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    protected function playerRow(FixtureLineupPlayer $player): array
    {
        return [
            'id' => $player->player_id,
            'name' => $player->player_name,
            'photo' => $player->photo_path,
            'number' => $player->number,
            'position' => $player->position,
            'grid' => $player->grid,
        ];
    }
}
