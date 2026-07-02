<?php

namespace Tests\Feature\Api;

use App\Models\Banner;
use App\Models\Club;
use App\Models\Listing;
use App\Models\Player;
use App\Models\Team;
use App\Models\User;
use App\Support\Enums\BannerPlacement;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class BannerSearchTest extends TestCase
{
    use RefreshDatabase;

    public function test_banners_require_auth(): void
    {
        $this->getJson('/api/v1/banners')->assertUnauthorized();
    }

    public function test_banners_returns_only_live_ones_filtered_by_placement(): void
    {
        Banner::factory()->create(['placement' => BannerPlacement::HomeTop, 'position' => 2]);
        Banner::factory()->create(['placement' => BannerPlacement::HomeTop, 'position' => 1]);
        Banner::factory()->create(['placement' => BannerPlacement::MarketplaceTop]);
        Banner::factory()->create(['placement' => BannerPlacement::HomeTop, 'is_active' => false]);
        Banner::factory()->create([
            'placement' => BannerPlacement::HomeTop,
            'starts_at' => now()->addDay(),
        ]);
        Banner::factory()->create([
            'placement' => BannerPlacement::HomeTop,
            'ends_at' => now()->subDay(),
        ]);

        $this->actingAs(User::factory()->create(), 'sanctum')
            ->getJson('/api/v1/banners?placement=home_top')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.position', 1);
    }

    public function test_global_search_returns_typed_results(): void
    {
        Team::factory()->create(['name_en' => 'Zamalek United', 'name_ar' => 'الزمالك']);
        Player::factory()->create(['name_en' => 'Zaman Player', 'name_ar' => 'زمان']);
        Club::factory()->create(['name_en' => 'Zawraa Club', 'name_ar' => 'الزوراء']);
        Listing::factory()->published()->create(['title_en' => 'Zara Jersey', 'title_ar' => 'زارا']);

        $response = $this->actingAs(User::factory()->create(), 'sanctum')
            ->getJson('/api/v1/search?q=Za')
            ->assertOk()
            ->assertJsonPath('data.query', 'Za');

        $types = collect($response->json('data.results'))->pluck('type')->unique()->values()->all();
        $this->assertContains('team', $types);
        $this->assertContains('club', $types);
        $this->assertContains('listing', $types);

        foreach ($response->json('data.results') as $item) {
            $this->assertArrayHasKey('type', $item);
            $this->assertArrayHasKey('id', $item);
            $this->assertArrayHasKey('title', $item);
        }
    }

    public function test_search_can_be_scoped_to_a_single_type(): void
    {
        Team::factory()->create(['name_en' => 'Najaf Team']);
        Club::factory()->create(['name_en' => 'Najaf Club']);

        $results = $this->actingAs(User::factory()->create(), 'sanctum')
            ->getJson('/api/v1/search?q=Najaf&type=club')
            ->assertOk()
            ->json('data.results');

        $this->assertNotEmpty($results);
        foreach ($results as $item) {
            $this->assertSame('club', $item['type']);
        }
    }

    public function test_search_requires_two_characters(): void
    {
        $this->actingAs(User::factory()->create(), 'sanctum')
            ->getJson('/api/v1/search?q=a')
            ->assertOk()
            ->assertJsonPath('data.results', []);
    }
}
