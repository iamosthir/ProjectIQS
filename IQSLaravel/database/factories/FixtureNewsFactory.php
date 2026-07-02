<?php

namespace Database\Factories;

use App\Models\FixtureNews;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<FixtureNews>
 */
class FixtureNewsFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $titleAr = $this->faker->realText(60);

        return [
            'title_ar' => $titleAr,
            'title_en' => $this->faker->sentence(6),
            'excerpt_ar' => $this->faker->realText(120),
            'excerpt_en' => $this->faker->sentence(14),
            'content_ar' => $this->faker->realText(600),
            'content_en' => $this->faker->paragraphs(3, true),
            'cover_path' => null,
            'source' => $this->faker->randomElement(['IQS', 'الاتحاد العراقي', 'وكالة الأنباء']),
            'url' => null,
            'is_published' => true,
            'published_at' => $this->faker->dateTimeBetween('-5 days', 'now'),
            'display_order' => 0,
        ];
    }
}

