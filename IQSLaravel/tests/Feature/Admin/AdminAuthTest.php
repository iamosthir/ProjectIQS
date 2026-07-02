<?php

namespace Tests\Feature\Admin;

use App\Models\Admin;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminAuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_login_and_fetch_me(): void
    {
        $admin = Admin::factory()->create(['email' => 'boss@iqs.app']);

        $this->postJson('/admin/api/v1/login', [
            'email' => 'boss@iqs.app',
            'password' => 'password',
        ])
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.admin.email', 'boss@iqs.app')
            ->assertJsonStructure(['data' => ['admin', 'roles', 'permissions']]);

        $this->assertNotNull($admin->fresh()->last_login_at);

        $this->getJson('/admin/api/v1/me')
            ->assertOk()
            ->assertJsonPath('data.admin.email', 'boss@iqs.app');
    }

    public function test_login_rejects_invalid_credentials(): void
    {
        Admin::factory()->create(['email' => 'boss@iqs.app']);

        $this->postJson('/admin/api/v1/login', [
            'email' => 'boss@iqs.app',
            'password' => 'wrong-password',
        ])
            ->assertStatus(422)
            ->assertJsonValidationErrors('email');
    }

    public function test_inactive_admin_cannot_login(): void
    {
        Admin::factory()->inactive()->create(['email' => 'ghost@iqs.app']);

        $this->postJson('/admin/api/v1/login', [
            'email' => 'ghost@iqs.app',
            'password' => 'password',
        ])->assertStatus(403);

        $this->getJson('/admin/api/v1/me')->assertStatus(401);
    }

    public function test_me_requires_authentication(): void
    {
        $this->getJson('/admin/api/v1/me')->assertStatus(401);
    }

    public function test_logout_ends_the_session(): void
    {
        $admin = Admin::factory()->create();
        $this->actingAs($admin, 'web');

        $this->postJson('/admin/api/v1/logout')->assertOk();
    }
}
