<?php

namespace App\Http\Resources;

use App\Models\Fixture;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Full fixture detail: the canonical list shape plus officials, broadcasts,
 * events, lineups, statistics, social state, and the prediction summary +
 * the caller's own prediction (§2.5).
 *
 * @mixin Fixture
 */
class FixtureDetailResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $base = (new FixtureResource($this->resource))->toArray($request);
        $total = $this->predictions_count;
        $pct = fn (int $count): int => $total > 0 ? (int) round($count * 100 / $total) : 0;

        return array_merge($base, [
            'officials' => [
                'referee' => $this->referee,
                'assistant_1' => $this->referee_assistant_1,
                'assistant_2' => $this->referee_assistant_2,
                'fourth_official' => $this->referee_fourth_official,
                'supervisor' => $this->supervisor,
            ],
            'broadcasts' => BroadcastResource::collection($this->whenLoaded('broadcasts')),
            'events' => FixtureEventResource::collection($this->whenLoaded('events')),
            'lineups' => LineupResource::collection($this->whenLoaded('lineups')),
            'statistics' => StatisticResource::collection($this->whenLoaded('statistics')),
            'social' => [
                'likes' => $this->likes_count,
                'comments' => $this->comments_count,
                'shares' => $this->shares_count,
                'liked_by_me' => $this->liked_by_me ?? false,
            ],
            'prediction' => [
                'total' => $total,
                'home_percent' => $pct($this->predict_home_count),
                'draw_percent' => $pct($this->predict_draw_count),
                'away_percent' => $pct($this->predict_away_count),
                'is_open' => $this->isPredictable(),
                'my_prediction' => $this->my_prediction ? new PredictionResource($this->my_prediction) : null,
            ],
        ]);
    }
}
