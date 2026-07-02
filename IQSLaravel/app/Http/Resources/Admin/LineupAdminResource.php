<?php

namespace App\Http\Resources\Admin;

use App\Models\FixtureLineup;
use App\Models\FixtureLineupPlayer;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin FixtureLineup
 */
class LineupAdminResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'fixture_id' => $this->fixture_id,
            'team_id' => $this->team_id,
            'formation' => $this->formation,
            'coach_id' => $this->coach_id,
            'coach_name' => $this->coach_name,
            'coach_photo' => $this->coach_photo,
            'players' => $this->whenLoaded('players', fn () => $this->players->map(fn (FixtureLineupPlayer $p) => [
                'id' => $p->id,
                'player_id' => $p->player_id,
                'player_name' => $p->player_name,
                'photo_path' => $p->photo_path,
                'number' => $p->number,
                'position' => $p->position,
                'grid' => $p->grid,
                'is_starter' => $p->is_starter,
            ])),
        ];
    }
}
