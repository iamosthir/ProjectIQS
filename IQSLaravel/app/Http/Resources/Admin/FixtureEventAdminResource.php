<?php

namespace App\Http\Resources\Admin;

use App\Models\FixtureEvent;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin FixtureEvent
 */
class FixtureEventAdminResource extends JsonResource
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
            'player_id' => $this->player_id,
            'assist_player_id' => $this->assist_player_id,
            'player_name' => $this->player_name,
            'assist_name' => $this->assist_name,
            'elapsed' => $this->elapsed,
            'extra' => $this->extra,
            'type' => $this->type?->value,
            'detail' => $this->detail,
            'comments' => $this->comments,
            'display_order' => $this->display_order,
        ];
    }
}
