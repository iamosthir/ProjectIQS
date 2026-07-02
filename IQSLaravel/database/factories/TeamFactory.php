<?php

namespace Database\Factories;

use App\Support\Enums\Source;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\Team>
 */
class TeamFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $name = fake()->unique()->city();

        return [
            'source' => Source::Manual,
            'external_id' => null,
            'name_ar' => 'نادي '.$name,
            'name_en' => $name.' FC',
            'short_code' => strtoupper(substr($name, 0, 3)),
            'country_name' => 'Iraq',
            'is_active' => true,
        ];
    }

    public function apiFootball(int $externalId): static
    {
        return $this->state(fn () => [
            'source' => Source::ApiFootball,
            'external_id' => $externalId,
            'last_synced_at' => now(),
        ]);
    }
}
