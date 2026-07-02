<?php

namespace Database\Factories;

use App\Support\Enums\Source;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\Player>
 */
class PlayerFactory extends Factory
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
            'position' => fake()->randomElement(['Goalkeeper', 'Defender', 'Midfielder', 'Attacker']),
            'nationality' => 'Iraq',
        ];
    }
}
