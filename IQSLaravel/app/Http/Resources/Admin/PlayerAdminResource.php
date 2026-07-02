<?php

namespace App\Http\Resources\Admin;

use App\Models\Player;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Player
 */
class PlayerAdminResource extends JsonResource
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
            'name_ar' => $this->name_ar,
            'name_en' => $this->name_en,
            'firstname' => $this->firstname,
            'lastname' => $this->lastname,
            'date_of_birth' => $this->date_of_birth?->toDateString(),
            'nationality' => $this->nationality,
            'birth_place' => $this->birth_place,
            'birth_country' => $this->birth_country,
            'height' => $this->height,
            'weight' => $this->weight,
            'photo_path' => $this->photo_path,
            'position' => $this->position,
            'is_injured' => $this->is_injured,
        ];
    }
}
