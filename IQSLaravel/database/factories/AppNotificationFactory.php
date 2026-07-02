<?php

namespace Database\Factories;

use App\Models\User;
use App\Support\Enums\NotificationType;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\AppNotification>
 */
class AppNotificationFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'title_ar' => fake()->sentence(3),
            'title_en' => fake()->sentence(3),
            'body_ar' => fake()->sentence(),
            'body_en' => fake()->sentence(),
            'type' => NotificationType::General,
            'sent_at' => now(),
        ];
    }

    public function read(): static
    {
        return $this->state(fn () => ['is_read' => true, 'read_at' => now()]);
    }
}
