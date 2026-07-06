<?php

namespace App\Http\Resources\Admin;

use App\Models\Season;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Season
 */
class SeasonAdminResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'league_id' => $this->league_id,
            'source' => $this->source?->value,
            'year' => $this->year,
            'label' => $this->label,
            'start_date' => $this->start_date?->toDateString(),
            'end_date' => $this->end_date?->toDateString(),
            'is_current' => $this->is_current,
            'auto_sync' => $this->auto_sync,
            'fixtures_synced_at' => $this->fixtures_synced_at?->toIso8601String(),
            'standings_synced_at' => $this->standings_synced_at?->toIso8601String(),
            'teams_synced_at' => $this->teams_synced_at?->toIso8601String(),
            'top_scorers_synced_at' => $this->top_scorers_synced_at?->toIso8601String(),
            'league' => $this->whenLoaded('league', fn () => [
                'id' => $this->league->id,
                'external_id' => $this->league->external_id,
                'name_ar' => $this->league->name_ar,
                'name_en' => $this->league->name_en,
                'logo_path' => $this->league->logo_path,
                'country_name' => $this->league->country_name,
            ]),
        ];
    }
}
