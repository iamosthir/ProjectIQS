<?php

namespace App\Http\Resources;

use App\Models\Club;
use App\Support\Localize;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Club
 */
class ClubResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => Localize::pick($this->name_ar, $this->name_en),
            'slug' => $this->slug,
            'logo' => $this->logo_path,
            'cover' => $this->cover_path,
            'governorate' => $this->governorate,
            'city' => $this->city,
            'founded_year' => $this->founded_year,
            'is_verified' => $this->is_verified,
            'team_id' => $this->team_id,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
