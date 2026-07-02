<?php

namespace Database\Factories;

use App\Models\Fixture;
use App\Models\User;
use App\Support\Enums\CommentContext;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\Comment>
 */
class CommentFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'commentable_type' => (new Fixture)->getMorphClass(),
            'commentable_id' => Fixture::factory(),
            'context' => CommentContext::Match,
            'body' => fake()->sentence(),
        ];
    }
}
