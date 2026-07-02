<?php

namespace App\Observers;

use App\Models\Fixture;
use App\Models\FixturePrediction;
use App\Support\Enums\PredictionOutcome;

/**
 * Maintains the aggregate prediction counters on the fixture used for the
 * home/draw/away percentage display.
 */
class FixturePredictionObserver
{
    public function created(FixturePrediction $prediction): void
    {
        Fixture::whereKey($prediction->fixture_id)->increment('predictions_count');
        Fixture::whereKey($prediction->fixture_id)->increment($this->column($prediction->predicted_outcome));
    }

    public function updated(FixturePrediction $prediction): void
    {
        if (! $prediction->wasChanged('predicted_outcome')) {
            return;
        }

        $original = $prediction->getOriginal('predicted_outcome');
        $original = $original instanceof PredictionOutcome ? $original : PredictionOutcome::from($original);

        Fixture::whereKey($prediction->fixture_id)->decrement($this->column($original));
        Fixture::whereKey($prediction->fixture_id)->increment($this->column($prediction->predicted_outcome));
    }

    public function deleted(FixturePrediction $prediction): void
    {
        Fixture::whereKey($prediction->fixture_id)->where('predictions_count', '>', 0)->decrement('predictions_count');
        Fixture::whereKey($prediction->fixture_id)->decrement($this->column($prediction->predicted_outcome));
    }

    protected function column(PredictionOutcome $outcome): string
    {
        return 'predict_'.$outcome->value.'_count';
    }
}
