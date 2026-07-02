<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<\App\Models\Page>
 */
class PageFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $title = fake()->unique()->words(2, true);

        return [
            'slug' => Str::slug($title),
            'title_ar' => $title,
            'title_en' => ucwords($title),
            'content_ar' => fake()->paragraphs(2, true),
            'content_en' => fake()->paragraphs(2, true),
            'is_active' => true,
        ];
    }
}
