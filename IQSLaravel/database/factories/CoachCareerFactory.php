<?php

namespace Database\Factories;

use App\Models\Coach;
use App\Models\CoachCareer;
use App\Models\Team;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<CoachCareer>
 */
class CoachCareerFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'coach_id' => Coach::factory(),
            'team_id' => Team::factory(),
            'start_date' => fake()->dateTimeBetween('-6 years', '-2 years'),
            'end_date' => fake()->optional()->dateTimeBetween('-2 years', 'now'),
        ];
    }
}
