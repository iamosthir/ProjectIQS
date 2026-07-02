<?php

namespace App\Http\Controllers\Admin\Matches;

use App\Http\Controllers\Controller;
use App\Http\Resources\PredictionResource;
use App\Models\Fixture;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PredictionOversightController extends Controller
{
    public function index(Request $request, Fixture $fixture): JsonResponse
    {
        $predictions = $fixture->predictions()
            ->with('user')
            ->orderBy('created_at')
            ->paginate($this->perPage($request))
            ->appends($request->query());

        $stats = [
            'total' => $fixture->predictions_count,
            'home' => $fixture->predict_home_count,
            'draw' => $fixture->predict_draw_count,
            'away' => $fixture->predict_away_count,
            'settled' => $fixture->predictions_settled,
            'correct' => $fixture->predictions()->where('is_correct', true)->count(),
            'exact' => $fixture->predictions()->where('is_exact_score', true)->count(),
        ];

        return $this->ok(PredictionResource::collection($predictions), 'OK', 200, ['stats' => $stats]);
    }
}
