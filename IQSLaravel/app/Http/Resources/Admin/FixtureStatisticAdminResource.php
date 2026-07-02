<?php

namespace App\Http\Resources\Admin;

use App\Models\FixtureStatistic;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin FixtureStatistic
 */
class FixtureStatisticAdminResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'fixture_id' => $this->fixture_id,
            'team_id' => $this->team_id,
            'type' => $this->type,
            'value' => $this->value,
            'value_numeric' => $this->value_numeric !== null ? (float) $this->value_numeric : null,
            'source' => $this->source?->value,
            'display_order' => $this->display_order,
        ];
    }
}
