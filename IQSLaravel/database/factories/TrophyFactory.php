<?php

namespace Database\Factories;

use App\Models\Player;
use App\Models\Trophy;
use App\Support\Enums\Source;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Trophy>
 */
class TrophyFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'source' => Source::Manual,
            'player_id' => Player::factory(),
            'league_name' => fake()->randomElement(['Iraq Stars League', 'Iraq FA Cup', 'AFC Champions League']),
            'country' => 'Iraq',
            'season' => fake()->randomElement(['2022/2023', '2023/2024', '2024/2025']),
            'place' => fake()->randomElement(['Winner', '2nd Place']),
        ];
    }
}
