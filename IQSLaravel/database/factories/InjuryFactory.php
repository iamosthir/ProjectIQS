<?php

namespace Database\Factories;

use App\Models\Injury;
use App\Models\Player;
use App\Models\Team;
use App\Support\Enums\Source;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Injury>
 */
class InjuryFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'source' => Source::Manual,
            'player_id' => Player::factory(),
            'team_id' => Team::factory(),
            'type' => fake()->randomElement([Injury::TYPE_MISSING_FIXTURE, Injury::TYPE_QUESTIONABLE]),
            'reason' => fake()->randomElement(['Knee Injury', 'Illness', 'Broken ankle', 'Suspended', 'Muscle Injury']),
            'date' => fake()->dateTimeBetween('-1 month', '+1 week'),
        ];
    }
}
