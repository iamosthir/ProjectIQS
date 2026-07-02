<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\PredictionResource;
use App\Models\Fixture;
use App\Models\FixturePrediction;
use App\Services\Match\LikeService;
use App\Support\Enums\PredictionOutcome;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PredictionController extends Controller
{
    public function __construct(private readonly LikeService $likes) {}

    /**
     * Percentages out of 100 + counts + the caller's own prediction.
     */
    public function summary(Request $request, Fixture $fixture): JsonResponse
    {
        $total = $fixture->predictions_count;
        $pct = fn (int $count): int => $total > 0 ? (int) round($count * 100 / $total) : 0;
        $mine = $fixture->predictions()->where('user_id', $request->user()->id)->first();

        return $this->ok([
            'total' => $total,
            'home_percent' => $pct($fixture->predict_home_count),
            'draw_percent' => $pct($fixture->predict_draw_count),
            'away_percent' => $pct($fixture->predict_away_count),
            'counts' => [
                'home' => $fixture->predict_home_count,
                'draw' => $fixture->predict_draw_count,
                'away' => $fixture->predict_away_count,
            ],
            'is_open' => $fixture->isPredictable(),
            'my_prediction' => $mine ? new PredictionResource($mine) : null,
        ]);
    }

    public function store(Request $request, Fixture $fixture): JsonResponse
    {
        if (! $fixture->isPredictable()) {
            return $this->fail(__('Predictions are closed for this match.'), null, 422);
        }

        $data = $request->validate([
            'home' => ['required', 'integer', 'min:0', 'max:99'],
            'away' => ['required', 'integer', 'min:0', 'max:99'],
        ]);

        $prediction = FixturePrediction::updateOrCreate(
            ['fixture_id' => $fixture->id, 'user_id' => $request->user()->id],
            [
                'predicted_home_score' => $data['home'],
                'predicted_away_score' => $data['away'],
                'predicted_outcome' => PredictionOutcome::fromScores($data['home'], $data['away']),
            ],
        );

        return $this->ok(new PredictionResource($prediction), __('Prediction saved.'));
    }

    /**
     * Correct predictions, oldest-first (after FT).
     */
    public function correct(Request $request, Fixture $fixture): JsonResponse
    {
        $predictions = $fixture->predictions()
            ->where('is_correct', true)
            ->with('user')
            ->orderBy('created_at')
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok(PredictionResource::collection($predictions));
    }

    public function like(Request $request, FixturePrediction $prediction): JsonResponse
    {
        $this->likes->like($request->user(), $prediction);

        return $this->ok(['likes_count' => $prediction->fresh()->likes_count], __('Liked.'));
    }

    public function unlike(Request $request, FixturePrediction $prediction): JsonResponse
    {
        $this->likes->unlike($request->user(), $prediction);

        return $this->ok(['likes_count' => $prediction->fresh()->likes_count], __('Unliked.'));
    }
}
