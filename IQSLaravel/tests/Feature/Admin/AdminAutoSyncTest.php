<?php

namespace Tests\Feature\Admin;

use App\Models\Admin;
use App\Models\League;
use App\Models\Season;
use App\Support\Enums\Source;
use Database\Seeders\RolesPermissionsSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
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
