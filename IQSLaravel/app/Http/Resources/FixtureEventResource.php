<?php

namespace App\Http\Resources;

use App\Models\FixtureEvent;
use App\Support\Localize;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin FixtureEvent
 */
class FixtureEventResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'team_id' => $this->team_id,
            'player' => [
                'id' => $this->player_id,
                'name' => $this->player_name ?: ($this->player ? Localize::pick($this->player->name_ar, $this->player->name_en) : null),
            ],
            'assist' => [
                'id' => $this->assist_player_id,
                'name' => $this->assist_name ?: ($this->assistPlayer ? Localize::pick($this->assistPlayer->name_ar, $this->assistPlayer->name_en) : null),
            ],
            'elapsed' => $this->elapsed,
            'extra' => $this->extra,
            'type' => $this->type?->value,
            'detail' => $this->detail,
            'comments' => $this->comments,
        ];
    }
}
