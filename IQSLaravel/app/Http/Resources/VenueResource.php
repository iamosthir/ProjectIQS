<?php

namespace App\Http\Resources;

use App\Models\Venue;
use App\Support\Localize;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Venue
 */
class VenueResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => Localize::pick($this->name_ar, $this->name_en),
            'city' => $this->city,
            'address' => $this->address,
            'capacity' => $this->capacity,
            'surface' => $this->surface,
            'image' => $this->image_path,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
        ];
    }
}
