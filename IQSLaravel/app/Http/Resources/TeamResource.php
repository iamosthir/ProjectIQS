<?php

namespace App\Http\Resources;

use App\Models\Team;
use App\Support\Localize;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Team
 */
class TeamResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => Localize::pick($this->name_ar, $this->name_en),
            'short_code' => $this->short_code,
            'logo' => $this->logo_path,
            'country' => $this->country_name,
            'is_national' => $this->is_national,
            'founded_year' => $this->founded_year,
            'club_id' => $this->club_id,
            'venue' => $this->whenLoaded('venue', fn () => $this->venue ? new VenueResource($this->venue) : null),
        ];
    }
}
