<?php

namespace Database\Factories;

use App\Models\League;
use App\Models\Season;
use App\Models\Team;
use App\Support\Enums\Source;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\Standing>
 */
class StandingFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $win = fake()->numberBetween(0, 20);
        $draw = fake()->numberBetween(0, 10);
        $lose = fake()->numberBetween(0, 15);

        return [
            'league_id' => League::factory(),
            'season_id' => Season::factory(),
            'team_id' => Team::factory(),
            'source' => Source::Manual,
            'group_label' => '',
            'rank' => fake()->numberBetween(1, 20),
            'points' => $win * 3 + $draw,
            'played' => $win + $draw + $lose,
            'win' => $win,
            'draw' => $draw,
            'lose' => $lose,
        ];
    }
}
