<?php

namespace Database\Factories;

use App\Models\Fixture;
use App\Models\FixturePlayerStatistic;
use App\Models\Player;
use App\Models\Team;
use App\Support\Enums\Source;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<FixturePlayerStatistic>
 */
class FixturePlayerStatisticFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'source' => Source::Manual,
            'fixture_id' => Fixture::factory(),
            'team_id' => Team::factory(),
            'player_id' => Player::factory(),
            'minutes' => fake()->numberBetween(1, 90),
            'number' => fake()->numberBetween(1, 40),
            'position' => fake()->randomElement(['G', 'D', 'M', 'F']),
            'rating' => fake()->randomFloat(2, 5.5, 9),
            'captain' => false,
            'substitute' => fake()->boolean(30),
            'shots_total' => fake()->numberBetween(0, 6),
            'goals_total' => fake()->numberBetween(0, 2),
            'passes_total' => fake()->numberBetween(5, 90),
            'passes_accuracy' => fake()->numberBetween(40, 95).'%',
        ];
    }
}
