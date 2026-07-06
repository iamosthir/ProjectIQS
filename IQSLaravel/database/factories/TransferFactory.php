<?php

namespace Database\Factories;

use App\Models\Player;
use App\Models\Team;
use App\Models\Transfer;
use App\Support\Enums\Source;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Transfer>
 */
class TransferFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'source' => Source::Manual,
            'player_id' => Player::factory(),
            'transfer_date' => fake()->dateTimeBetween('-4 years', 'now'),
            'type' => fake()->randomElement(['Free', 'Loan', 'N/A', '€ 1.2M']),
            'team_in_id' => Team::factory(),
            'team_out_id' => Team::factory(),
        ];
    }
}
