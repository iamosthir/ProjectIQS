<?php

namespace Database\Factories;

use App\Models\Country;
use App\Support\Enums\Source;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Country>
 */
class CountryFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $name = fake()->unique()->country();

        return [
            'source' => Source::Manual,
            'name_ar' => $name,
            'name_en' => $name,
            'code' => strtoupper(fake()->unique()->lexify('??')),
            'is_active' => true,
        ];
    }
}
