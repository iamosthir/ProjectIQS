<?php

namespace App\Http\Resources;

use App\Models\Player;
use App\Support\Localize;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Player
 */
class PlayerResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => Localize::pick($this->name_ar, $this->name_en),
            'firstname' => $this->firstname,
            'lastname' => $this->lastname,
            'date_of_birth' => $this->date_of_birth?->toDateString(),
            'nationality' => $this->nationality,
            'birth_place' => $this->birth_place,
            'birth_country' => $this->birth_country,
            'height' => $this->height,
            'weight' => $this->weight,
            'photo' => $this->photo_path,
            'position' => $this->position,
            'is_injured' => $this->is_injured,
            'number' => $this->whenPivotLoaded('team_player', fn () => $this->pivot->number),
        ];
    }
}
