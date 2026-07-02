<?php

namespace Database\Factories;

use App\Models\MarketplaceCategory;
use App\Models\Store;
use App\Models\User;
use App\Support\Enums\ListingStatus;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\Listing>
 */
class ListingFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'store_id' => Store::factory(),
            'user_id' => User::factory(),
            'category_id' => MarketplaceCategory::factory(),
            'title_ar' => 'إعلان '.fake()->jobTitle(),
            'title_en' => fake()->jobTitle(),
            'full_name' => fake()->name(),
            'governorate' => 'Baghdad',
            'show_contact' => true,
            'status' => ListingStatus::Draft,
            'attributes' => [],
        ];
    }

    /**
     * Tie the listing's owner to its store's owner.
     */
    public function ownedBy(User $user): static
    {
        return $this->state(fn () => [
            'user_id' => $user->id,
            'store_id' => Store::factory()->create(['user_id' => $user->id])->id,
        ]);
    }

    public function status(ListingStatus $status): static
    {
        return $this->state(fn () => ['status' => $status]);
    }

    public function published(): static
    {
        return $this->state(fn () => [
            'status' => ListingStatus::Published,
            'published_at' => now(),
        ]);
    }
}
