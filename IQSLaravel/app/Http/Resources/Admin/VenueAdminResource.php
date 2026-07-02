<?php

namespace App\Http\Resources\Admin;

use App\Models\Venue;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Venue
 */
class VenueAdminResource extends JsonResource
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
            'address' => $this->address,
            'city' => $this->city,
            'capacity' => $this->capacity,
            'surface' => $this->surface,
            'image_path' => $this->image_path,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
        ];
    }
}
