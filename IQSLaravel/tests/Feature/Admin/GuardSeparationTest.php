<?php

namespace Tests\Feature\Admin;

use App\Models\Admin;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Enforces the §0.4 auth separation: the two guards never cross over.
 */
class GuardSeparationTest extends TestCase
{
    use RefreshDatabase;

    public function test_app_user_token_cannot_reach_admin_api(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->getJson('/admin/api/v1/me')->assertStatus(401);
        $this->getJson('/admin/api/v1/admins')->assertStatus(401);
    }

    public function test_admin_session_cannot_reach_mobile_api(): void
    {
        $admin = Admin::factory()->create();
        $this->actingAs($admin, 'web');

        // No Sanctum token + no session fallback guard → unauthenticated.
        $this->getJson('/api/v1/auth/me')->assertStatus(401);
    }
}
