<?php

namespace Database\Factories;

use App\Models\Fixture;
use App\Models\FixtureEvent;
use App\Models\Team;
use App\Support\Enums\Source;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<FixtureEvent>
 */
class FixtureEventFactory extends Factory
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
            'player_name' => fake()->name('male'),
            'elapsed' => fake()->numberBetween(1, 90),
            'type' => 'goal',
            'detail' => 'Normal Goal',
        ];
    }
}
