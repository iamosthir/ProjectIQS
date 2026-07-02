<?php

namespace Tests\Feature\Api;

use App\Models\AppNotification;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class NotificationTest extends TestCase
{
    use RefreshDatabase;

    public function test_device_register_is_idempotent_and_unregister_removes_it(): void
    {
        $user = User::factory()->create();
        $this->actingAs($user, 'sanctum');

        $this->postJson('/api/v1/devices/register', ['token' => 'tok-1', 'platform' => 'android'])->assertOk();
        $this->postJson('/api/v1/devices/register', ['token' => 'tok-1', 'platform' => 'android'])->assertOk();

        $this->assertSame(1, $user->deviceTokens()->count());

        $this->deleteJson('/api/v1/devices/unregister', ['token' => 'tok-1'])->assertOk();
        $this->assertDatabaseMissing('device_tokens', ['token' => 'tok-1']);
    }

    public function test_notifications_list_unread_count_and_read_flow(): void
    {
        $user = User::factory()->create();
        AppNotification::factory()->count(2)->for($user)->create();
        $read = AppNotification::factory()->for($user)->read()->create();
        $this->actingAs($user, 'sanctum');

        $this->getJson('/api/v1/notifications')->assertOk()->assertJsonCount(3, 'data');
        $this->getJson('/api/v1/notifications?unread=1')->assertOk()->assertJsonCount(2, 'data');
        $this->getJson('/api/v1/notifications/unread-count')->assertOk()->assertJsonPath('data.count', 2);

        $unread = AppNotification::where('user_id', $user->id)->unread()->first();
        $this->postJson("/api/v1/notifications/{$unread->id}/read")->assertOk()->assertJsonPath('data.is_read', true);

        $this->postJson('/api/v1/notifications/read-all')->assertOk();
        $this->assertSame(0, AppNotification::where('user_id', $user->id)->unread()->count());
    }

    public function test_a_user_cannot_read_another_users_notification(): void
    {
        $other = AppNotification::factory()->create();

        $this->actingAs(User::factory()->create(), 'sanctum')
            ->postJson("/api/v1/notifications/{$other->id}/read")
            ->assertStatus(403);
    }
}
