<?php

namespace Tests\Feature\Admin;

use App\Models\Admin;
use Database\Seeders\RolesPermissionsSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminPermissionTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RolesPermissionsSeeder::class);
    }

    public function test_super_admin_can_list_admins(): void
    {
        $admin = Admin::factory()->create();
        $admin->assignRole('super-admin');

        $this->actingAs($admin, 'web')
            ->getJson('/admin/api/v1/admins')
            ->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_admin_without_permission_is_forbidden(): void
    {
        $admin = Admin::factory()->create();
        $admin->assignRole('content-editor'); // lacks "manage admins"

        $this->actingAs($admin, 'web')
            ->getJson('/admin/api/v1/admins')
            ->assertStatus(403);
    }

    public function test_super_admin_can_create_admin_with_role(): void
    {
        $admin = Admin::factory()->create();
        $admin->assignRole('super-admin');

        $this->actingAs($admin, 'web')
            ->postJson('/admin/api/v1/admins', [
                'name' => 'New Editor',
                'email' => 'editor@iqs.app',
                'password' => 'secret123',
                'password_confirmation' => 'secret123',
                'roles' => ['content-editor'],
            ])
            ->assertCreated()
            ->assertJsonPath('data.email', 'editor@iqs.app')
            ->assertJsonPath('data.roles.0', 'content-editor');

        $this->assertDatabaseHas('admins', ['email' => 'editor@iqs.app']);
    }

    public function test_super_admin_role_cannot_be_deleted(): void
    {
        $admin = Admin::factory()->create();
        $admin->assignRole('super-admin');

        $roleId = \Spatie\Permission\Models\Role::where('name', 'super-admin')->where('guard_name', 'web')->value('id');

        $this->actingAs($admin, 'web')
            ->deleteJson("/admin/api/v1/roles/{$roleId}")
            ->assertStatus(422);
    }
}
