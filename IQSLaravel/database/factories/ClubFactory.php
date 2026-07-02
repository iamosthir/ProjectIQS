<?php

namespace Database\Factories;

use App\Models\User;
use App\Support\Enums\ClubStatus;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\Club>
 */
class ClubFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $name = fake()->unique()->city();

        return [
            'name_ar' => 'نادي '.$name,
            'name_en' => $name.' SC',
            'governorate' => 'Baghdad',
            'founded_year' => fake()->numberBetween(1930, 2010),
            'status' => ClubStatus::Active,
            'is_active' => true,
        ];
    }

    public function verified(): static
    {
        return $this->state(fn () => ['is_verified' => true, 'verified_at' => now()]);
    }

    public function managedBy(User $user): static
    {
        return $this->state(fn () => ['managed_by' => $user->id]);
    }
}
