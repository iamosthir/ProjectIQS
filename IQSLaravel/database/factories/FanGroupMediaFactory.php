<?php

namespace Database\Factories;

use App\Models\FanGroup;
use App\Support\Enums\FanGroupMediaType;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\FanGroupMedia>
 */
class FanGroupMediaFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'fan_group_id' => FanGroup::factory(),
            'type' => FanGroupMediaType::Image,
            'path' => 'fan-groups/'.fake()->uuid().'.jpg',
        ];
    }

    public function video(): static
    {
        return $this->state(fn () => ['type' => FanGroupMediaType::Video, 'path' => 'fan-groups/'.fake()->uuid().'.mp4']);
    }
}
