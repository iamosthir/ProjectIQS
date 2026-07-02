<?php

namespace Database\Factories;

use App\Models\User;
use App\Support\Enums\FanGroupStatus;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\FanGroup>
 */
class FanGroupFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $name = fake()->unique()->words(2, true);

        return [
            'name_ar' => 'رابطة '.$name,
            'name_en' => ucwords($name).' Ultras',
            'governorate' => 'Baghdad',
            'founded_year' => fake()->numberBetween(1990, 2020),
            'status' => FanGroupStatus::Active,
            'is_active' => true,
        ];
    }

    public function managedBy(User $user): static
    {
        return $this->state(fn () => ['managed_by' => $user->id]);
    }

    public function verified(): static
    {
        return $this->state(fn () => ['is_verified' => true, 'is_official' => true, 'verified_at' => now()]);
    }
}
