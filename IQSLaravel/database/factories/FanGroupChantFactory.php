<?php

namespace Database\Factories;

use App\Models\FanGroup;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\FanGroupChant>
 */
class FanGroupChantFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'fan_group_id' => FanGroup::factory(),
            'title_ar' => fake()->words(3, true),
            'video_path' => 'fan-groups/chants/'.fake()->uuid().'.mp4',
        ];
    }
}
