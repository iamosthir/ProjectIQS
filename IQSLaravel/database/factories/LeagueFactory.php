<?php

namespace Database\Factories;

use App\Support\Enums\LeagueCategory;
use App\Support\Enums\LeagueType;
use App\Support\Enums\Source;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\League>
 */
class LeagueFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $name = fake()->unique()->words(2, true);

        return [
            'source' => Source::Manual,
            'external_id' => null,
            'name_ar' => 'دوري '.$name,
            'name_en' => ucwords($name).' League',
            'type' => LeagueType::League,
            'is_iraqi' => true,
            'category' => LeagueCategory::Premier,
            'tier' => 1,
            'requires_auth' => true,
            'is_active' => true,
        ];
    }

    public function apiFootball(int $externalId): static
    {
        return $this->state(fn () => [
            'source' => Source::ApiFootball,
            'external_id' => $externalId,
            'category' => LeagueCategory::Other,
            'last_synced_at' => now(),
        ]);
    }
}
