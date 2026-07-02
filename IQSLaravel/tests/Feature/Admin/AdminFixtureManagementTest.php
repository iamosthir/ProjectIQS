<?php

namespace Tests\Feature\Admin;

use App\Models\Admin;
use App\Models\Fixture;
use App\Models\Player;
use Database\Seeders\RolesPermissionsSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Professional fixture-management additions: statistics entry, event editing,
 * lineups with images/player links, and per-fixture news.
 */
class AdminFixtureManagementTest extends TestCase
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

    public function test_admin_can_bulk_save_and_replace_statistics(): void
    {
        $fixture = Fixture::factory()->create();

        $this->postJson("/admin/api/v1/fixtures/{$fixture->id}/statistics", [
            'statistics' => [
                ['team_id' => $fixture->home_team_id, 'type' => 'Ball Possession', 'value' => '58%'],
                ['team_id' => $fixture->away_team_id, 'type' => 'Ball Possession', 'value' => '42%'],
                ['team_id' => $fixture->home_team_id, 'type' => 'Total Shots', 'value' => '12', 'value_numeric' => 12],
            ],
        ])
            ->assertOk()
            ->assertJsonCount(3, 'data');

        $this->assertTrue($fixture->fresh()->has_statistics);
        $this->assertDatabaseHas('fixture_statistics', [
            'fixture_id' => $fixture->id,
            'type' => 'Ball Possession',
            'value' => '58%',
            'source' => 'manual',
        ]);

        // Re-saving replaces the manual set (no duplication).
        $this->postJson("/admin/api/v1/fixtures/{$fixture->id}/statistics", [
            'statistics' => [
                ['team_id' => $fixture->home_team_id, 'type' => 'Corner Kicks', 'value' => '5'],
            ],
        ])
            ->assertOk()
            ->assertJsonCount(1, 'data');

        $this->assertSame(1, $fixture->fresh()->statistics()->count());
    }

    public function test_admin_can_edit_an_event(): void
    {
        $fixture = Fixture::factory()->create();
        $event = $fixture->events()->create([
            'source' => 'manual', 'type' => 'goal', 'detail' => 'Normal Goal', 'elapsed' => 10, 'display_order' => 0,
        ]);

        $this->putJson("/admin/api/v1/fixtures/{$fixture->id}/events/{$event->id}", [
            'elapsed' => 42, 'detail' => 'Penalty', 'player_name' => 'Corrected Name',
        ])
            ->assertOk()
            ->assertJsonPath('data.elapsed', 42)
            ->assertJsonPath('data.detail', 'Penalty')
            ->assertJsonPath('data.player_name', 'Corrected Name');
    }

    public function test_lineup_saves_player_link_photo_and_coach_photo(): void
    {
        $fixture = Fixture::factory()->create();
        $player = Player::factory()->create();

        $this->postJson("/admin/api/v1/fixtures/{$fixture->id}/lineups", [
            'team_id' => $fixture->home_team_id,
            'formation' => '4-4-2',
            'coach_name' => 'Radhi Shenaishil',
            'coach_photo' => 'lineups/coach.jpg',
            'players' => [
                [
                    'player_id' => $player->id,
                    'player_name' => $player->name_en,
                    'photo_path' => 'lineups/p1.jpg',
                    'number' => 10,
                    'position' => 'M',
                    'is_starter' => true,
                ],
            ],
        ])
            ->assertOk()
            ->assertJsonPath('data.coach_photo', 'lineups/coach.jpg')
            ->assertJsonPath('data.players.0.player_id', $player->id)
            ->assertJsonPath('data.players.0.photo_path', 'lineups/p1.jpg');

        $this->assertDatabaseHas('fixture_lineup_players', [
            'player_id' => $player->id,
            'photo_path' => 'lineups/p1.jpg',
        ]);
    }

    public function test_admin_can_crud_fixture_news_including_unpublished(): void
    {
        $fixture = Fixture::factory()->create();

        $newsId = $this->postJson("/admin/api/v1/fixtures/{$fixture->id}/news", [
            'title_ar' => 'عنوان الخبر',
            'title_en' => 'Match Report',
            'content_ar' => 'محتوى',
            'cover_path' => 'fixture_news/cover.jpg',
            'is_published' => true,
        ])
            ->assertCreated()
            ->assertJsonPath('data.source', 'manual')
            ->assertJsonPath('data.title_en', 'Match Report')
            ->json('data.id');

        // Unpublish it, then confirm the ADMIN index still returns it.
        $this->putJson("/admin/api/v1/fixtures/{$fixture->id}/news/{$newsId}", [
            'is_published' => false, 'title_en' => 'Updated',
        ])
            ->assertOk()
            ->assertJsonPath('data.is_published', false)
            ->assertJsonPath('data.title_en', 'Updated');

        $this->getJson("/admin/api/v1/fixtures/{$fixture->id}/news")
            ->assertOk()
            ->assertJsonCount(1, 'data');

        $this->deleteJson("/admin/api/v1/fixtures/{$fixture->id}/news/{$newsId}")->assertOk();
        $this->assertDatabaseMissing('fixture_news', ['id' => $newsId]);
    }

    public function test_new_detail_endpoints_require_manage_matches_permission(): void
    {
        $support = Admin::factory()->create();
        $support->assignRole('support'); // lacks "manage matches"
        $fixture = Fixture::factory()->create();

        $this->actingAs($support, 'web')
            ->getJson("/admin/api/v1/fixtures/{$fixture->id}/statistics")
            ->assertStatus(403);
    }
}
