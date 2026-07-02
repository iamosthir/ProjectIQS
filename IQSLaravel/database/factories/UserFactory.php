<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<User>
 */
class UserFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'phone' => '+9647'.fake()->numerify('#########'),
            'phone_verified_at' => now(),
            'name' => fake()->name(),
            'email' => null,
            'governorate' => fake()->randomElement([
                'Baghdad', 'Basra', 'Erbil', 'Najaf', 'Karbala', 'Mosul',
            ]),
            'locale' => 'ar',
            'is_active' => true,
            'is_banned' => false,
            'registration_completed_at' => now(),
            'last_active_at' => now(),
        ];
    }

    /**
     * A user that has verified OTP but not yet completed their profile.
     */
    public function unregistered(): static
    {
        return $this->state(fn (array $attributes) => [
            'name' => null,
            'registration_completed_at' => null,
        ]);
    }

    /**
     * A user whose phone has not yet been verified.
     */
    public function unverified(): static
    {
        return $this->state(fn (array $attributes) => [
            'phone_verified_at' => null,
            'registration_completed_at' => null,
            'name' => null,
        ]);
    }

    public function banned(): static
    {
        return $this->state(fn (array $attributes) => [
            'is_banned' => true,
            'banned_reason' => fake()->sentence(),
        ]);
    }
}
