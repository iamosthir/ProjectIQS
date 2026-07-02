<?php

namespace Database\Factories;

use App\Models\Fixture;
use App\Models\Team;
use App\Support\Enums\Source;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\FixtureStatistic>
 */
class FixtureStatisticFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $value = (string) $this->faker->numberBetween(0, 100);

        return [
            'fixture_id' => Fixture::factory(),
            'team_id' => Team::factory(),
            'source' => Source::Manual,
            'type' => $this->faker->randomElement([
                'Ball Possession', 'Total Shots', 'Shots on Goal', 'Corner Kicks', 'Fouls',
            ]),
            'value' => $value,
            'value_numeric' => (float) $value,
            'display_order' => 0,
        ];
    }

    public function apiFootball(): static
    {
        return $this->state(fn () => ['source' => Source::ApiFootball]);
    }
}
