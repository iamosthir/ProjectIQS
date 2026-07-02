<?php

namespace Database\Factories;

use App\Support\Enums\Currency;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<\App\Models\MarketplaceCategory>
 */
class MarketplaceCategoryFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $name = fake()->unique()->word();

        return [
            'key' => Str::slug($name).'-'.fake()->unique()->numberBetween(1, 99999),
            'name_ar' => $name,
            'name_en' => ucfirst($name),
            'base_price' => 20000,
            'currency' => Currency::IQD,
            'is_free' => false,
            'requires_contact_button' => true,
            'field_schema' => ['fields' => [], 'media' => ['image' => 6, 'video' => 1, 'document' => 1]],
            'is_active' => true,
        ];
    }

    public function free(): static
    {
        return $this->state(fn () => ['is_free' => true, 'base_price' => 0]);
    }
}
