<?php

namespace Database\Factories;

use App\Models\League;
use App\Models\Player;
use App\Models\PlayerStatistic;
use App\Models\Season;
use App\Models\Team;
use App\Support\Enums\Source;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<PlayerStatistic>
 */
class PlayerStatisticFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $appearances = fake()->numberBetween(1, 38);

        return [
            'source' => Source::Manual,
            'player_id' => Player::factory(),
            'team_id' => Team::factory(),
            'league_id' => League::factory(),
            'season_id' => Season::factory(),
            'appearances' => $appearances,
            'lineups' => fake()->numberBetween(0, $appearances),
            'minutes' => $appearances * fake()->numberBetween(45, 90),
            'position' => fake()->randomElement(['Goalkeeper', 'Defender', 'Midfielder', 'Attacker']),
            'rating' => fake()->randomFloat(2, 5.5, 9),
            'goals_total' => fake()->numberBetween(0, 30),
            'goals_assists' => fake()->numberBetween(0, 15),
            'cards_yellow' => fake()->numberBetween(0, 12),
            'cards_red' => fake()->numberBetween(0, 3),
        ];
    }
}
