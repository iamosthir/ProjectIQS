<?php

namespace Database\Factories;

use App\Models\League;
use App\Support\Enums\Source;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\Season>
 */
class SeasonFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $year = 2025;

        return [
            'league_id' => League::factory(),
            'source' => Source::Manual,
            'year' => $year,
            'label' => $year.'-'.($year + 1),
            'is_current' => true,
        ];
    }
}
