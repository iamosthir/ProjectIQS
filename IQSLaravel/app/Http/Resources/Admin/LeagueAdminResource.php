<?php

namespace App\Http\Resources\Admin;

use App\Models\League;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin League
 */
class LeagueAdminResource extends JsonResource
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
            'type' => $this->type?->value,
            'logo_path' => $this->logo_path,
            'country_name' => $this->country_name,
            'country_code' => $this->country_code,
            'country_flag' => $this->country_flag,
            'is_iraqi' => $this->is_iraqi,
            'category' => $this->category?->value,
            'tier' => $this->tier,
            'requires_auth' => $this->requires_auth,
            'is_featured' => $this->is_featured,
            'display_order' => $this->display_order,
            'is_active' => $this->is_active,
            'is_locked' => $this->is_locked,
            'last_synced_at' => $this->last_synced_at?->toIso8601String(),
            'seasons_count' => $this->whenCounted('seasons'),
            'current_season' => $this->whenLoaded('currentSeason', fn () => $this->currentSeason ? [
                'id' => $this->currentSeason->id,
                'year' => $this->currentSeason->year,
            ] : null),
        ];
    }
}
