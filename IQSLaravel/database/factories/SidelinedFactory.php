<?php

namespace Database\Factories;

use App\Models\Player;
use App\Models\Sidelined;
use App\Support\Enums\Source;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Sidelined>
 */
class SidelinedFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $start = fake()->dateTimeBetween('-2 years', '-1 month');

        return [
            'source' => Source::Manual,
            'player_id' => Player::factory(),
            'type' => fake()->randomElement(['Suspended', 'Hamstring', 'Knee Injury', 'Ankle/Foot Injury']),
            'start_date' => $start,
            'end_date' => fake()->dateTimeBetween($start, 'now'),
        ];
    }
}
