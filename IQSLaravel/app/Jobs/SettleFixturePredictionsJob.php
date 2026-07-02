<?php

namespace App\Jobs;

use App\Models\Fixture;
use App\Models\FixturePrediction;
use App\Support\Enums\FixtureStatusGroup;
use App\Support\Enums\MatchWinner;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;

/**
 * On a fixture reaching `finished` (via sync:live or the manual "End of Match"
 * event) settle `is_correct` / `is_exact_score` for every prediction (§2.4).
 */
class SettleFixturePredictionsJob implements ShouldQueue
{
    use Queueable;

    public function __construct(public readonly int $fixtureId) {}

    public function handle(): void
    {
        $fixture = Fixture::find($this->fixtureId);

        if ($fixture === null
            || $fixture->status_group !== FixtureStatusGroup::Finished
            || $fixture->predictions_settled) {
            return;
        }

        $home = $fixture->home_goals;
        $away = $fixture->away_goals;
        $winner = $fixture->winner?->value ?? MatchWinner::fromScores($home, $away)?->value;

        $fixture->predictions()->chunkById(500, function ($predictions) use ($winner, $home, $away): void {
            foreach ($predictions as $prediction) {
                /** @var FixturePrediction $prediction */
                $correct = $winner !== null && $prediction->predicted_outcome->value === $winner;
                $exact = $home !== null && $away !== null
                    && $prediction->predicted_home_score === $home
                    && $prediction->predicted_away_score === $away;

                $prediction->forceFill([
                    'is_correct' => $correct,
                    'is_exact_score' => $exact,
                ])->saveQuietly();
            }
        });

        $fixture->forceFill(['predictions_settled' => true])->saveQuietly();
    }
}
