<?php

namespace Tests\Feature\Admin;

use App\Models\Admin;
use App\Models\League;
use App\Models\Season;
use App\Support\Enums\Source;
use Database\Seeders\RolesPermissionsSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class AdminAutoSyncTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RolesPermissionsSeeder::class);
        $admin = Admin::factory()->create();
        $admin->assignRole('super-admin');
        $this->actingAs($admin, 'web');
    }

    public function test_admin_can_subscribe_an_api_league_season_to_auto_sync(): void
    {
        $league = League::factory()->apiFootball(39)->create();
        $season = Season::factory()->for($league)->create([
            'source' => Source::ApiFootball,
            'fixtures_synced_at' => now(),
        ]);

        $this->postJson("/admin/api/v1/sync/auto/seasons/{$season->id}", ['enabled' => true])
            ->assertOk()
            ->assertJsonPath('data.auto_sync', true)
            // Watermarks reset so the first full pull happens on the next tick.
            ->assertJsonPath('data.fixtures_synced_at', null);

        $this->postJson("/admin/api/v1/sync/auto/seasons/{$season->id}", ['enabled' => false])
            ->assertOk()
            ->assertJsonPath('data.auto_sync', false);
    }

    public function test_manual_league_seasons_cannot_be_auto_synced(): void
    {
        $season = Season::factory()->create(); // manual league, no external id

        $this->postJson("/admin/api/v1/sync/auto/seasons/{$season->id}", ['enabled' => true])
            ->assertStatus(422);

        $this->assertFalse($season->refresh()->auto_sync);
    }

    public function test_subscribing_activates_an_inactive_league(): void
    {
        $league = League::factory()->apiFootball(39)->create(['is_active' => false]);
        $season = Season::factory()->for($league)->create(['source' => Source::ApiFootball]);

        $this->postJson("/admin/api/v1/sync/auto/seasons/{$season->id}", ['enabled' => true])
            ->assertOk()
            ->assertJsonPath('data.auto_sync', true);

        $this->assertTrue($league->refresh()->is_active);
    }

    public function test_countries_can_be_synced_and_listed_for_the_picker(): void
    {
        Http::fake(['*' => Http::response(['response' => [
            ['name' => 'England', 'code' => 'GB-ENG', 'flag' => 'gb-eng.svg'],
        ]], 200)]);

        $this->postJson('/admin/api/v1/sync/countries')
            ->assertOk()
            ->assertJsonPath('data.processed', 1);

        $this->getJson('/admin/api/v1/sync/countries')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name_en', 'England');
    }

    public function test_sync_now_force_runs_all_tiers_for_a_season(): void
    {
        $league = League::factory()->apiFootball(140)->create();
        $season = Season::factory()->for($league)->create(['source' => Source::ApiFootball, 'year' => 2024]);

        Http::fake(['*' => Http::response(['response' => []], 200)]);

        $this->postJson("/admin/api/v1/sync/auto/seasons/{$season->id}/run")
            ->assertOk()
            ->assertJsonStructure(['data' => ['processed']]);

        $season->refresh();
        $this->assertNotNull($season->fixtures_synced_at);
        $this->assertNotNull($season->standings_synced_at);
        $this->assertNotNull($season->teams_synced_at);
        $this->assertNotNull($season->top_scorers_synced_at);
    }

    public function test_sync_now_rejects_manual_league_seasons(): void
    {
        $season = Season::factory()->create(); // manual league

        $this->postJson("/admin/api/v1/sync/auto/seasons/{$season->id}/run")
            ->assertStatus(422);
    }

    public function test_auto_status_lists_subscriptions_with_budget_and_intervals(): void
    {
        $league = League::factory()->apiFootball(39)->create();
        Season::factory()->for($league)->create([
            'source' => Source::ApiFootball,
            'auto_sync' => true,
        ]);

        $this->getJson('/admin/api/v1/sync/auto')
            ->assertOk()
            ->assertJsonCount(1, 'data.seasons')
            ->assertJsonPath('data.seasons.0.auto_sync', true)
            ->assertJsonPath('data.seasons.0.league.external_id', 39)
            ->assertJsonStructure(['data' => ['budget_remaining', 'intervals', 'live_poll_seconds']]);
    }
}
