<?php

namespace Database\Factories;

use App\Models\User;
use App\Support\Enums\DevicePlatform;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<\App\Models\DeviceToken>
 */
class DeviceTokenFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'token' => 'fcm_'.Str::random(60),
            'platform' => DevicePlatform::Android,
            'is_active' => true,
            'last_used_at' => now(),
        ];
    }

    public function inactive(): static
    {
        return $this->state(fn () => ['is_active' => false]);
    }
}
