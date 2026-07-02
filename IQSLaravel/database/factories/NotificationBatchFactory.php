<?php

namespace Database\Factories;

use App\Models\Admin;
use App\Support\Enums\NotificationBatchStatus;
use App\Support\Enums\NotificationTarget;
use App\Support\Enums\NotificationType;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\NotificationBatch>
 */
class NotificationBatchFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'admin_id' => Admin::factory(),
            'title_ar' => fake()->sentence(3),
            'title_en' => fake()->sentence(3),
            'body_ar' => fake()->sentence(),
            'body_en' => fake()->sentence(),
            'target' => NotificationTarget::All,
            'type' => NotificationType::General,
            'status' => NotificationBatchStatus::Draft,
        ];
    }
}
