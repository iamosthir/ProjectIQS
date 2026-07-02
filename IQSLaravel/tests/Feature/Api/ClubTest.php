<?php

namespace Tests\Feature\Api;

use App\Models\Club;
use App\Models\ClubBoardMember;
use App\Models\ClubNews;
use App\Models\Setting;
use App\Models\User;
use App\Support\Enums\SettingType;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ClubTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->actingAs(User::factory()->create(), 'sanctum');
    }

    public function test_clubs_index_returns_active_clubs(): void
    {
        Club::factory()->count(2)->create();

        $this->getJson('/api/v1/clubs')->assertOk()->assertJsonCount(2, 'data');
    }

    public function test_club_show_returns_full_page_with_org_chart_board(): void
    {
        $club = Club::factory()->create();
        $chair = ClubBoardMember::factory()->for($club)->create(['position_en' => 'Chairman']);
        ClubBoardMember::factory()->for($club)->create(['parent_id' => $chair->id, 'position_en' => 'Vice']);

        $response = $this->getJson("/api/v1/clubs/{$club->id}")
            ->assertOk()
            ->assertJsonStructure(['data' => ['id', 'name', 'location', 'contact', 'board', 'staff', 'titles', 'captains', 'competitions']])
            ->assertJsonCount(2, 'data.board');

        // The hierarchy is expressed via parent_id (renderable as an org chart).
        $this->assertSame($chair->id, $response->json('data.board.1.parent_id'));
    }

    public function test_published_news_list_and_article_view_increments_views(): void
    {
        $club = Club::factory()->create();
        ClubNews::factory()->draft()->for($club)->create();
        $published = ClubNews::factory()->for($club)->create();

        $this->getJson("/api/v1/clubs/{$club->id}/news")->assertOk()->assertJsonCount(1, 'data');

        $this->getJson("/api/v1/clubs/{$club->id}/news/{$published->id}")
            ->assertOk()
            ->assertJsonStructure(['data' => ['content']]);

        $this->assertSame(1, $published->fresh()->views_count);
    }

    public function test_verify_request_is_gated_by_the_season_flag(): void
    {
        $club = Club::factory()->create();

        // Off by default → hidden.
        $this->postJson("/api/v1/clubs/{$club->id}/verify-request", ['method' => 'message'])->assertStatus(403);

        Setting::set('clubs', 'verification_enabled', true, SettingType::Boolean);

        $this->postJson("/api/v1/clubs/{$club->id}/verify-request", ['method' => 'message'])
            ->assertCreated()
            ->assertJsonPath('data.status', 'pending');

        $this->assertDatabaseHas('club_verifications', ['club_id' => $club->id, 'method' => 'message']);
    }

    public function test_club_admin_can_manage_their_club_and_board(): void
    {
        $user = User::factory()->create();
        $club = Club::factory()->managedBy($user)->create();
        $this->actingAs($user, 'sanctum');

        $this->getJson('/api/v1/my-club')->assertOk()->assertJsonPath('data.id', $club->id);
        $this->putJson('/api/v1/my-club', ['description_ar' => 'وصف النادي'])->assertOk();

        $member = $this->postJson('/api/v1/my-club/board', [
            'name_ar' => 'رئيس', 'name_en' => 'Chairman', 'position_ar' => 'رئيس', 'position_en' => 'Chairman',
        ])->assertCreated()->json('data.id');

        $this->putJson("/api/v1/my-club/board/{$member}", ['name_en' => 'President'])->assertOk();
        $this->deleteJson("/api/v1/my-club/board/{$member}")->assertOk();
        $this->assertDatabaseMissing('club_board_members', ['id' => $member]);
    }

    public function test_a_user_without_a_managed_club_cannot_use_my_club(): void
    {
        $this->actingAs(User::factory()->create(), 'sanctum')
            ->getJson('/api/v1/my-club')
            ->assertStatus(403);
    }
}
