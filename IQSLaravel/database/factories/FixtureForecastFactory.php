<?php

namespace Database\Factories;

use App\Models\Fixture;
use App\Models\FixtureForecast;
use App\Support\Enums\Source;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<FixtureForecast>
 */
class FixtureForecastFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $home = fake()->numberBetween(20, 60);
        $draw = fake()->numberBetween(10, 100 - $home - 10);

        return [
            'source' => Source::Manual,
            'fixture_id' => Fixture::factory(),
            'win_or_draw' => fake()->boolean(),
            'under_over' => fake()->randomElement(['-2.5', '+1.5', '-3.5', null]),
            'goals_home' => '-2.5',
            'goals_away' => '-1.5',
            'advice' => 'Double chance : draw or home team',
            'percent_home' => $home,
            'percent_draw' => $draw,
            'percent_away' => 100 - $home - $draw,
            'comparison' => [
                'form' => ['home' => '55%', 'away' => '45%'],
                'att' => ['home' => '60%', 'away' => '40%'],
                'def' => ['home' => '50%', 'away' => '50%'],
                'total' => ['home' => '55%', 'away' => '45%'],
            ],
        ];
    }
}
