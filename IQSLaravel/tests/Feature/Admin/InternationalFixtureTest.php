<?php

namespace Tests\Feature\Admin;

use App\Models\Admin;
use App\Models\League;
use App\Models\Team;
use Database\Seeders\InternationalSeeder;
use Database\Seeders\RolesPermissionsSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Country-vs-country (FIFA) fixture support: the international seeder and the
 * end-to-end creation of a fixture between two national teams.
 */
class InternationalFixtureTest extends TestCase
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

    public function test_seeder_creates_fifa_competition_and_national_teams_with_flags(): void
    {
        $this->seed(InternationalSeeder::class);

        $this->assertDatabaseHas('leagues', [
            'name_en' => 'FIFA World Cup Qualifiers — Asia',
            'is_iraqi' => false,
            'source' => 'manual',
        ]);

        $iraq = Team::where('name_en', 'Iraq')->where('is_national', true)->first();
        $this->assertNotNull($iraq);
        $this->assertSame('https://flagcdn.com/w320/iq.png', $iraq->logo_path);
        $this->assertSame('Iraq', $iraq->country_name);

        $this->assertSame(18, Team::where('is_national', true)->count());

        // Idempotent: re-running must not duplicate anything.
        $this->seed(InternationalSeeder::class);
        $this->assertSame(18, Team::where('is_national', true)->count());
        $this->assertSame(1, League::where('name_en', 'FIFA World Cup Qualifiers — Asia')->count());
    }

    public function test_admin_can_create_a_country_vs_country_fixture(): void
    {
        $this->seed(InternationalSeeder::class);

        $league = League::where('name_en', 'FIFA World Cup Qualifiers — Asia')->firstOrFail();
        $iraq = Team::where('name_en', 'Iraq')->where('is_national', true)->firstOrFail();
        $saudi = Team::where('name_en', 'Saudi Arabia')->where('is_national', true)->firstOrFail();

        $this->postJson('/admin/api/v1/fixtures', [
            'league_id' => $league->id,
            'home_team_id' => $iraq->id,
            'away_team_id' => $saudi->id,
            'match_datetime' => now()->addWeek()->toIso8601String(),
            'round' => 'Round 3',
        ])
            ->assertCreated()
            ->assertJsonPath('data.source', 'manual')
            ->assertJsonPath('data.home_team.logo', 'https://flagcdn.com/w320/iq.png')
            ->assertJsonPath('data.away_team.logo', 'https://flagcdn.com/w320/sa.png');
    }

    public function test_team_picker_search_finds_national_teams_server_side(): void
    {
        $this->seed(InternationalSeeder::class);
        // Bury the national teams behind >50 alphabetically-earlier club teams
        // (the picker pages at 50) — server-side search must still find them.
        Team::factory()->count(55)->sequence(fn ($s) => ['name_en' => sprintf('AA Club %02d', $s->index)])->create();

        $this->getJson('/admin/api/v1/teams?filter[search]=Saudi')
            ->assertOk()
            ->assertJsonPath('data.0.name_en', 'Saudi Arabia');
    }
}
