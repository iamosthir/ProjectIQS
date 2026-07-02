<?php

namespace Tests\Feature\Api;

use App\Models\FanGroup;
use App\Models\FanGroupChant;
use App\Models\FanGroupMedia;
use App\Models\Setting;
use App\Models\User;
use App\Support\Enums\SettingType;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class FanGroupTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->actingAs(User::factory()->create(), 'sanctum');
    }

    public function test_index_and_show_return_groups_with_archive_counts(): void
    {
        $group = FanGroup::factory()->create();
        FanGroupMedia::factory()->count(3)->for($group)->create();
        FanGroupMedia::factory()->count(2)->video()->for($group)->create();
        FanGroupChant::factory()->for($group)->create();

        $this->getJson('/api/v1/fan-groups')->assertOk()->assertJsonCount(1, 'data');

        $this->getJson("/api/v1/fan-groups/{$group->id}")
            ->assertOk()
            ->assertJsonPath('data.counts.photos', 3)
            ->assertJsonPath('data.counts.videos', 2)
            ->assertJsonPath('data.counts.chants', 1)
            ->assertJsonStructure(['data' => ['documents', 'contact']]);
    }

    public function test_media_archive_is_filterable_by_type(): void
    {
        $group = FanGroup::factory()->create();
        FanGroupMedia::factory()->count(4)->for($group)->create();
        FanGroupMedia::factory()->count(2)->video()->for($group)->create();

        $this->getJson("/api/v1/fan-groups/{$group->id}/media?type=video")
            ->assertOk()
            ->assertJsonCount(2, 'data');
    }

    public function test_verify_request_is_gated_by_the_season_flag(): void
    {
        $group = FanGroup::factory()->create();

        $this->postJson("/api/v1/fan-groups/{$group->id}/verify-request", ['method' => 'video'])->assertStatus(403);

        Setting::set('fan_groups', 'verification_enabled', true, SettingType::Boolean);

        $this->postJson("/api/v1/fan-groups/{$group->id}/verify-request", ['method' => 'video'])
            ->assertCreated()
            ->assertJsonPath('data.status', 'pending');

        $this->assertDatabaseHas('fan_group_verifications', ['fan_group_id' => $group->id, 'method' => 'video']);
    }

    public function test_group_admin_can_manage_archives(): void
    {
        $user = User::factory()->create();
        $group = FanGroup::factory()->managedBy($user)->create();
        $this->actingAs($user, 'sanctum');

        $this->getJson('/api/v1/my-fan-group')->assertOk()->assertJsonPath('data.id', $group->id);

        $media = $this->postJson('/api/v1/my-fan-group/media', ['type' => 'image', 'path' => 'a.jpg'])
            ->assertCreated()->json('data.id');
        $this->deleteJson("/api/v1/my-fan-group/media/{$media}")->assertOk();

        $this->postJson('/api/v1/my-fan-group/chants', ['video_path' => 'chant.mp4', 'title_ar' => 'هوسة'])->assertCreated();
        $this->postJson('/api/v1/my-fan-group/documents', ['path' => 'doc.pdf'])->assertCreated();
    }

    public function test_chant_archive_limit_is_enforced(): void
    {
        $user = User::factory()->create();
        $group = FanGroup::factory()->managedBy($user)->create();
        FanGroupChant::factory()->count(20)->for($group)->create(); // at the cap

        $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/my-fan-group/chants', ['video_path' => 'extra.mp4'])
            ->assertStatus(422)
            ->assertJsonValidationErrors('video_path');
    }

    public function test_video_archive_limit_is_enforced(): void
    {
        $user = User::factory()->create();
        $group = FanGroup::factory()->managedBy($user)->create();
        FanGroupMedia::factory()->count(30)->video()->for($group)->create(); // at the cap

        $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/my-fan-group/media', ['type' => 'video', 'path' => 'extra.mp4'])
            ->assertStatus(422)
            ->assertJsonValidationErrors('type');
    }

    public function test_a_user_without_a_managed_group_cannot_use_my_fan_group(): void
    {
        $this->getJson('/api/v1/my-fan-group')->assertStatus(403);
    }
}
