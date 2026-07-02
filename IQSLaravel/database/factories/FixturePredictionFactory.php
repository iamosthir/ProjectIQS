<?php

namespace Database\Factories;

use App\Models\Fixture;
use App\Models\User;
use App\Support\Enums\PredictionOutcome;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\FixturePrediction>
 */
class FixturePredictionFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $home = fake()->numberBetween(0, 4);
        $away = fake()->numberBetween(0, 4);

        return [
            'fixture_id' => Fixture::factory(),
            'user_id' => User::factory(),
            'predicted_home_score' => $home,
            'predicted_away_score' => $away,
            'predicted_outcome' => PredictionOutcome::fromScores($home, $away),
        ];
    }
}
