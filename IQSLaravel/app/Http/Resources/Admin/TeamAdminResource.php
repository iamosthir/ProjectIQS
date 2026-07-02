<?php

namespace App\Http\Resources\Admin;

use App\Models\Team;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Team
 */
class TeamAdminResource extends JsonResource
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
            'short_code' => $this->short_code,
            'country_name' => $this->country_name,
            'founded_year' => $this->founded_year,
            'is_national' => $this->is_national,
            'logo_path' => $this->logo_path,
            'venue_id' => $this->venue_id,
            'club_id' => $this->club_id,
            'is_active' => $this->is_active,
            'is_locked' => $this->is_locked,
            'venue' => $this->whenLoaded('venue', fn () => $this->venue ? [
                'id' => $this->venue->id,
                'name' => $this->venue->name_en,
            ] : null),
        ];
    }
}
