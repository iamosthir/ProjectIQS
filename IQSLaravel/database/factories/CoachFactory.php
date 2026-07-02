<?php

namespace Database\Factories;

use App\Support\Enums\Source;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\Coach>
 */
class CoachFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $name = fake()->name('male');

        return [
            'source' => Source::Manual,
            'name_ar' => $name,
            'name_en' => $name,
            'nationality' => 'Iraq',
        ];
    }
}
