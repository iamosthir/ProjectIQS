<?php

namespace Database\Factories;

use App\Support\Enums\Source;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\Venue>
 */
class VenueFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'source' => Source::Manual,
            'name_ar' => 'ملعب '.fake()->city(),
            'name_en' => fake()->city().' Stadium',
            'city' => fake()->city(),
            'capacity' => fake()->numberBetween(5000, 65000),
        ];
    }
}
