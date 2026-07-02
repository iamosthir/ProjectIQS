<?php

namespace App\Http\Resources;

use App\Models\FixtureStatistic;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin FixtureStatistic
 */
class StatisticResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'team_id' => $this->team_id,
            'type' => $this->type,
            'value' => $this->value,
            'value_numeric' => $this->value_numeric !== null ? (float) $this->value_numeric : null,
        ];
    }
}
