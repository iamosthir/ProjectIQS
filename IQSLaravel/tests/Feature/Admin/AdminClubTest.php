<?php

namespace Tests\Feature\Admin;

use App\Models\Admin;
use App\Models\Club;
use App\Models\ClubVerification;
use App\Models\User;
use Database\Seeders\RolesPermissionsSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminClubTest extends TestCase
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

    public function test_admin_can_create_a_club_and_assign_a_manager(): void
    {
        $manager = User::factory()->create();

        $this->actingAs($this->superAdmin(), 'web')
            ->postJson('/admin/api/v1/clubs', [
                'name_ar' => 'نادي بغداد', 'name_en' => 'Baghdad Club', 'managed_by' => $manager->id,
            ])
            ->assertCreated()
            ->assertJsonPath('data.name_en', 'Baghdad Club');

        // Assigning a manager grants the club-admin capability.
        $this->assertTrue($manager->fresh()->hasRole('club-admin'));
    }

    public function test_admin_can_verify_a_club(): void
    {
        $club = Club::factory()->create(['is_verified' => false]);

        $this->actingAs($this->superAdmin(), 'web')
            ->postJson("/admin/api/v1/clubs/{$club->id}/verify")
            ->assertOk()
            ->assertJsonPath('data.is_verified', true);
    }

    public function test_admin_can_add_nested_content(): void
    {
        $club = Club::factory()->create();

        $this->actingAs($this->superAdmin(), 'web')
            ->postJson("/admin/api/v1/clubs/{$club->id}/content/titles", [
                'title_ar' => 'دوري', 'title_en' => 'League Title', 'year' => 2024, 'count' => 7,
            ])
            ->assertCreated();

        $this->assertDatabaseHas('club_titles', ['club_id' => $club->id, 'title_en' => 'League Title']);
    }

    public function test_admin_can_review_verification_requests(): void
    {
        $pending = ClubVerification::factory()->create();
        $admin = $this->superAdmin();

        $this->actingAs($admin, 'web')
            ->getJson('/admin/api/v1/clubs/verifications')
            ->assertOk()
            ->assertJsonCount(1, 'data');

        $this->actingAs($admin, 'web')
            ->postJson("/admin/api/v1/clubs/verifications/{$pending->id}/approve")
            ->assertOk()
            ->assertJsonPath('data.status', 'approved');
    }

    public function test_clubs_require_the_manage_clubs_permission(): void
    {
        $support = Admin::factory()->create();
        $support->assignRole('support');

        $this->actingAs($support, 'web')
            ->getJson('/admin/api/v1/clubs')
            ->assertStatus(403);
    }
}
