<?php

namespace Database\Factories;

use App\Models\League;
use App\Support\Enums\Source;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\TopScorer>
 */
class TopScorerFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'source' => Source::Manual,
            'league_id' => League::factory(),
            'player_name' => fake()->name('male'),
            'team_name' => fake()->city().' FC',
            'goals' => fake()->numberBetween(1, 25),
        ];
    }
}
