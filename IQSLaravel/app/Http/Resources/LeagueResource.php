<?php

namespace App\Http\Resources;

use App\Models\League;
use App\Support\Localize;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin League
 */
class LeagueResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => Localize::pick($this->name_ar, $this->name_en),
            'type' => $this->type?->value,
            'logo' => $this->logo_path,
            'country' => [
                'name' => $this->country_name,
                'code' => $this->country_code,
                'flag' => $this->country_flag,
            ],
            'is_iraqi' => $this->is_iraqi,
            'category' => $this->category?->value,
            'tier' => $this->tier,
            'requires_auth' => $this->requires_auth,
            'is_featured' => $this->is_featured,
            'current_season' => $this->whenLoaded('currentSeason', fn () => $this->currentSeason ? [
                'id' => $this->currentSeason->id,
                'year' => $this->currentSeason->year,
                'label' => $this->currentSeason->label,
            ] : null),
        ];
    }
}
