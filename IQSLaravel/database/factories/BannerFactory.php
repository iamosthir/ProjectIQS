<?php

namespace Database\Factories;

use App\Support\Enums\BannerPlacement;
use App\Support\Enums\NotificationActionType;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\Banner>
 */
class BannerFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'title_ar' => fake()->sentence(2),
            'title_en' => fake()->sentence(2),
            'image_path' => 'banners/'.fake()->uuid().'.jpg',
            'action_type' => NotificationActionType::None,
            'placement' => BannerPlacement::HomeTop,
            'is_active' => true,
        ];
    }
}
