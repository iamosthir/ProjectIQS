<?php

namespace Tests\Feature\Admin;

use App\Models\Admin;
use App\Models\FanGroup;
use App\Models\FanGroupVerification;
use App\Models\User;
use Database\Seeders\RolesPermissionsSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminFanGroupTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RolesPermissionsSeeder::class);
    }

    private function superAdmin(): Admin
    {
        $admin = Admin::factory()->create();
        $admin->assignRole('super-admin');

        return $admin;
    }

    public function test_admin_can_create_a_fan_group_and_assign_a_manager(): void
    {
        $manager = User::factory()->create();

        $this->actingAs($this->superAdmin(), 'web')
            ->postJson('/admin/api/v1/fan-groups', [
                'name_ar' => 'الطلائع', 'name_en' => 'Vanguard Ultras', 'managed_by' => $manager->id,
            ])
            ->assertCreated();

        $this->assertTrue($manager->fresh()->hasRole('group-admin'));
    }

    public function test_admin_can_verify_a_fan_group(): void
    {
        $group = FanGroup::factory()->create(['is_verified' => false]);

        $this->actingAs($this->superAdmin(), 'web')
            ->postJson("/admin/api/v1/fan-groups/{$group->id}/verify")
            ->assertOk()
            ->assertJsonPath('data.is_verified', true)
            ->assertJsonPath('data.is_official', true);
    }

    public function test_admin_can_add_archive_media(): void
    {
        $group = FanGroup::factory()->create();

        $this->actingAs($this->superAdmin(), 'web')
            ->postJson("/admin/api/v1/fan-groups/{$group->id}/media", ['type' => 'image', 'path' => 'x.jpg'])
            ->assertCreated();

        $this->assertDatabaseHas('fan_group_media', ['fan_group_id' => $group->id, 'type' => 'image']);
    }

    public function test_admin_can_review_verifications(): void
    {
        $pending = FanGroupVerification::factory()->create();
        $admin = $this->superAdmin();

        $this->actingAs($admin, 'web')
            ->getJson('/admin/api/v1/fan-groups/verifications')
            ->assertOk()
            ->assertJsonCount(1, 'data');

        $this->actingAs($admin, 'web')
            ->postJson("/admin/api/v1/fan-groups/verifications/{$pending->id}/approve")
            ->assertOk()
            ->assertJsonPath('data.status', 'approved');
    }

    public function test_fan_groups_require_permission(): void
    {
        $support = Admin::factory()->create();
        $support->assignRole('support');

        $this->actingAs($support, 'web')
            ->getJson('/admin/api/v1/fan-groups')
            ->assertStatus(403);
    }
}
