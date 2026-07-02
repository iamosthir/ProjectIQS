<?php

namespace Tests\Feature\Admin;

use App\Models\Admin;
use App\Models\Comment;
use App\Models\Fixture;
use App\Models\FixturePrediction;
use App\Models\League;
use App\Models\Team;
use App\Support\Enums\PredictionOutcome;
use Database\Seeders\RolesPermissionsSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class AdminMatchModuleTest extends TestCase
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

    public function test_admin_can_create_a_manual_league(): void
    {
        $this->postJson('/admin/api/v1/leagues', [
            'name_ar' => 'دوري تجريبي',
            'name_en' => 'Test League',
            'tier' => 1,
        ])
            ->assertCreated()
            ->assertJsonPath('data.source', 'manual')
            ->assertJsonPath('data.name_en', 'Test League');
    }

    public function test_admin_can_create_a_manual_fixture_with_officials(): void
    {
        $league = League::factory()->create();
        $home = Team::factory()->create();
        $away = Team::factory()->create();

        $this->postJson('/admin/api/v1/fixtures', [
            'league_id' => $league->id,
            'home_team_id' => $home->id,
            'away_team_id' => $away->id,
            'match_datetime' => now()->addDay()->toIso8601String(),
            'referee' => 'Ali Sabah',
            'supervisor' => 'Hadi Karim',
        ])
            ->assertCreated()
            ->assertJsonPath('data.source', 'manual')
            ->assertJsonPath('data.status_group', 'scheduled')
            ->assertJsonPath('data.officials.referee', 'Ali Sabah')
            ->assertJsonPath('data.officials.supervisor', 'Hadi Karim');
    }

    public function test_lineup_pitch_builder_saves_players(): void
    {
        $fixture = Fixture::factory()->create();

        $this->postJson("/admin/api/v1/fixtures/{$fixture->id}/lineups", [
            'team_id' => $fixture->home_team_id,
            'formation' => '4-3-3',
            'players' => [
                ['player_name' => 'Goalkeeper', 'number' => 1, 'position' => 'G', 'grid' => '1:1', 'is_starter' => true],
                ['player_name' => 'Striker', 'number' => 9, 'position' => 'F', 'grid' => '4:2', 'is_starter' => true],
                ['player_name' => 'Sub One', 'number' => 12, 'is_starter' => false],
            ],
        ])
            ->assertOk()
            ->assertJsonPath('data.formation', '4-3-3')
            ->assertJsonCount(3, 'data.players');

        $this->assertTrue($fixture->fresh()->has_lineups);
    }

    public function test_logging_a_goal_event_bumps_the_top_scorer(): void
    {
        $fixture = Fixture::factory()->create();

        $this->postJson("/admin/api/v1/fixtures/{$fixture->id}/events", [
            'type' => 'goal', 'detail' => 'Normal Goal', 'elapsed' => 23,
            'team_id' => $fixture->home_team_id, 'player_name' => 'Aymen Hussein',
        ])->assertCreated();

        $this->assertDatabaseHas('top_scorers', [
            'league_id' => $fixture->league_id,
            'player_name' => 'Aymen Hussein',
            'goals' => 1,
        ]);

        // A second goal for the same scorer increments the tally.
        $this->postJson("/admin/api/v1/fixtures/{$fixture->id}/events", [
            'type' => 'goal', 'detail' => 'Penalty', 'elapsed' => 70,
            'team_id' => $fixture->home_team_id, 'player_name' => 'Aymen Hussein',
        ])->assertCreated();

        $this->assertDatabaseHas('top_scorers', ['player_name' => 'Aymen Hussein', 'goals' => 2]);
    }

    public function test_end_of_match_event_finishes_fixture_and_settles_predictions(): void
    {
        $fixture = Fixture::factory()->create(['home_goals' => 2, 'away_goals' => 1, 'winner' => 'home']);

        $prediction = FixturePrediction::create([
            'fixture_id' => $fixture->id,
            'user_id' => \App\Models\User::factory()->create()->id,
            'predicted_home_score' => 2,
            'predicted_away_score' => 1,
            'predicted_outcome' => PredictionOutcome::Home,
        ]);

        $this->postJson("/admin/api/v1/fixtures/{$fixture->id}/events", [
            'type' => 'match_end', 'detail' => 'Full Time', 'elapsed' => 90,
        ])->assertCreated();

        $this->assertSame('finished', $fixture->fresh()->status_group->value);
        $this->assertTrue($fixture->fresh()->predictions_settled);
        $this->assertTrue((bool) $prediction->fresh()->is_correct);
        $this->assertTrue((bool) $prediction->fresh()->is_exact_score);
    }

    public function test_top_scorer_crud_auto_ranks(): void
    {
        $league = League::factory()->create();

        $this->postJson("/admin/api/v1/leagues/{$league->id}/top-scorers", ['player_name' => 'A', 'goals' => 5])->assertCreated();
        $this->postJson("/admin/api/v1/leagues/{$league->id}/top-scorers", ['player_name' => 'B', 'goals' => 10])->assertCreated();

        $this->getJson("/admin/api/v1/leagues/{$league->id}/top-scorers")
            ->assertOk()
            ->assertJsonPath('data.0.player_name', 'B')
            ->assertJsonPath('data.0.rank', 1);
    }

    public function test_sync_console_triggers_a_league_sync(): void
    {
        Http::fake(['*' => Http::response(['response' => [[
            'league' => ['id' => 39, 'name' => 'Premier League', 'type' => 'League'],
            'country' => ['name' => 'England'],
            'seasons' => [['year' => 2025, 'current' => true]],
        ]]], 200, ['x-ratelimit-requests-remaining' => '90'])]);

        $this->postJson('/admin/api/v1/sync/leagues', ['iraqi' => false])
            ->assertOk()
            ->assertJsonPath('data.processed', 1);

        $this->assertDatabaseHas('leagues', ['external_id' => 39, 'source' => 'api_football']);
    }

    public function test_comment_moderation_hide_and_delete(): void
    {
        $fixture = Fixture::factory()->create();
        $comment = Comment::factory()->create([
            'commentable_id' => $fixture->id,
            'commentable_type' => $fixture->getMorphClass(),
        ]);

        $this->getJson('/admin/api/v1/comments')->assertOk()->assertJsonCount(1, 'data');

        $this->postJson("/admin/api/v1/comments/{$comment->id}/hide")
            ->assertOk()
            ->assertJsonPath('data.is_hidden', true);

        $this->deleteJson("/admin/api/v1/comments/{$comment->id}")->assertOk();
        $this->assertSoftDeleted('comments', ['id' => $comment->id]);
    }

    public function test_match_routes_require_the_manage_matches_permission(): void
    {
        $support = Admin::factory()->create();
        $support->assignRole('support'); // lacks "manage matches"

        $this->actingAs($support, 'web')
            ->getJson('/admin/api/v1/leagues')
            ->assertStatus(403);
    }
}
