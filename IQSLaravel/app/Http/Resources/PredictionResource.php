<?php

namespace App\Http\Resources;

use App\Models\FixturePrediction;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin FixturePrediction
 */
class PredictionResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'home' => $this->predicted_home_score,
            'away' => $this->predicted_away_score,
            'outcome' => $this->predicted_outcome?->value,
            'is_correct' => $this->is_correct,
            'is_exact_score' => $this->is_exact_score,
            'likes_count' => $this->likes_count,
            'liked_by_me' => $this->liked_by_me ?? false,
            'user' => $this->whenLoaded('user', fn () => [
                'id' => $this->user?->id,
                'name' => $this->user?->name,
                'avatar' => $this->user?->avatar,
            ]),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
