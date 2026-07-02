<?php

namespace Database\Factories;

use App\Models\User;
use App\Support\Enums\StoreStatus;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\Store>
 */
class StoreFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $name = fake()->company();

        return [
            'user_id' => User::factory(),
            'name_ar' => 'متجر '.$name,
            'name_en' => $name,
            'governorate' => 'Baghdad',
            'status' => StoreStatus::Active,
        ];
    }

    public function pending(): static
    {
        return $this->state(fn () => ['status' => StoreStatus::Pending]);
    }
}
