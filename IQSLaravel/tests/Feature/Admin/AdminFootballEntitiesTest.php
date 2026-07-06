<?php

namespace Tests\Feature\Admin;

use App\Models\Admin;
use App\Models\Coach;
use App\Models\Country;
use App\Models\Fixture;
use App\Models\Injury;
use App\Models\League;
use App\Models\Player;
use App\Models\PlayerStatistic;
use App\Models\Season;
use App\Models\Team;
use Database\Seeders\RolesPermissionsSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Admin CRUD for the API-Football parity entities added alongside the
 * /api/v1/football/* mirror (countries, coaches+careers, injuries,
 * transfers, trophies, sidelined, player statistics, forecasts).
 */
class AdminFootballEntitiesTest extends TestCase
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

    public function test_admin_can_crud_a_country(): void
    {
        $this->postJson('/admin/api/v1/countries', [
            'name_ar' => 'العراق',
            'name_en' => 'Iraq',
            'code' => 'IQ',
        ])
            ->assertCreated()
            ->assertJsonPath('data.code', 'IQ');

        $country = Country::firstOrFail();

        $this->putJson('/admin/api/v1/countries/'.$country->id, ['code' => 'IRQ'])
            ->assertOk()
            ->assertJsonPath('data.code', 'IRQ');

        $this->deleteJson('/admin/api/v1/countries/'.$country->id)->assertOk();
        $this->assertDatabaseCount('countries', 0);
    }

    public function test_admin_can_create_coach_with_career_entries(): void
    {
        $team = Team::factory()->create();

        $this->postJson('/admin/api/v1/coaches', [
            'name_ar' => 'مدرب',
            'name_en' => 'Coach Name',
            'team_id' => $team->id,
            'height' => '182 cm',
        ])->assertCreated();

        $coach = Coach::firstOrFail();

        $this->postJson("/admin/api/v1/coaches/{$coach->id}/careers", [
            'team_id' => $team->id,
            'start_date' => '2023-07-01',
        ])->assertCreated();

        $this->assertDatabaseHas('coach_careers', ['coach_id' => $coach->id, 'team_id' => $team->id]);

        $career = $coach->careers()->first();

        $this->putJson("/admin/api/v1/coaches/{$coach->id}/careers/{$career->id}", [
            'end_date' => '2025-06-30',
        ])->assertOk();

        $this->deleteJson("/admin/api/v1/coaches/{$coach->id}/careers/{$career->id}")->assertOk();
        $this->assertDatabaseCount('coach_careers', 0);
    }

    public function test_admin_can_record_an_injury(): void
    {
        $player = Player::factory()->create();
        $fixture = Fixture::factory()->create();

        $this->postJson('/admin/api/v1/injuries', [
            'player_id' => $player->id,
            'fixture_id' => $fixture->id,
            'type' => Injury::TYPE_MISSING_FIXTURE,
            'reason' => 'Knee Injury',
        ])
            ->assertCreated()
            ->assertJsonPath('data.reason', 'Knee Injury');
    }

    public function test_admin_can_record_transfer_trophy_and_sidelined(): void
    {
        $player = Player::factory()->create();
        $in = Team::factory()->create();
        $out = Team::factory()->create();

        $this->postJson('/admin/api/v1/transfers', [
            'player_id' => $player->id,
            'transfer_date' => '2025-07-01',
            'type' => 'Free',
            'team_in_id' => $in->id,
            'team_out_id' => $out->id,
        ])->assertCreated();

        $this->postJson('/admin/api/v1/trophies', [
            'player_id' => $player->id,
            'league_name' => 'Iraq Stars League',
            'season' => '2024/2025',
            'place' => 'Winner',
        ])->assertCreated();

        $this->postJson('/admin/api/v1/sidelined', [
            'player_id' => $player->id,
            'type' => 'Suspended',
            'start_date' => '2025-01-01',
            'end_date' => '2025-01-15',
        ])->assertCreated();

        // A trophy/sidelined row needs a player OR a coach.
        $this->postJson('/admin/api/v1/trophies', ['league_name' => 'X'])->assertStatus(422);
        $this->postJson('/admin/api/v1/sidelined', ['type' => 'X'])->assertStatus(422);
    }

    public function test_admin_can_enter_player_season_statistics_once_per_team_season(): void
    {
        $player = Player::factory()->create();
        $team = Team::factory()->create();
        $league = League::factory()->create();
        $season = Season::factory()->create(['league_id' => $league->id]);

        $payload = [
            'player_id' => $player->id,
            'team_id' => $team->id,
            'league_id' => $league->id,
            'season_id' => $season->id,
            'appearances' => 20,
            'goals_total' => 9,
            'rating' => 7.4,
        ];

        $this->postJson('/admin/api/v1/player-statistics', $payload)
            ->assertCreated()
            ->assertJsonPath('data.goals_total', 9);

        // The composite player×team×season key is enforced by validation.
        $this->postJson('/admin/api/v1/player-statistics', $payload)->assertStatus(422);

        $statistic = PlayerStatistic::firstOrFail();

        $this->putJson('/admin/api/v1/player-statistics/'.$statistic->id, ['goals_total' => 11])
            ->assertOk()
            ->assertJsonPath('data.goals_total', 11);
    }

    public function test_admin_can_manage_fixture_player_statistics_and_forecast(): void
    {
        $fixture = Fixture::factory()->finished()->create();
        $player = Player::factory()->create();

        $this->postJson("/admin/api/v1/fixtures/{$fixture->id}/player-statistics", [
            'team_id' => $fixture->home_team_id,
            'player_id' => $player->id,
            'minutes' => 90,
            'goals_total' => 2,
            'rating' => 8.1,
        ])
            ->assertCreated()
            ->assertJsonPath('data.minutes', 90);

        $this->putJson("/admin/api/v1/fixtures/{$fixture->id}/forecast", [
            'winner_team_id' => $fixture->home_team_id,
            'advice' => 'Home win',
            'percent_home' => 55,
            'percent_draw' => 25,
            'percent_away' => 20,
        ])
            ->assertOk()
            ->assertJsonPath('data.advice', 'Home win');

        // Upsert: a second PUT updates the same row.
        $this->putJson("/admin/api/v1/fixtures/{$fixture->id}/forecast", ['advice' => 'Changed'])
            ->assertOk()
            ->assertJsonPath('data.advice', 'Changed');

        $this->assertDatabaseCount('fixture_forecasts', 1);

        $this->deleteJson("/admin/api/v1/fixtures/{$fixture->id}/forecast")->assertOk();
        $this->assertDatabaseCount('fixture_forecasts', 0);
    }
}
