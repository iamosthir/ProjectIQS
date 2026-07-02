<?php

namespace Tests\Feature\Admin;

use App\Models\Admin;
use App\Models\AppNotification;
use App\Models\DeviceToken;
use App\Models\NotificationBatch;
use App\Models\User;
use App\Services\Notification\FcmSender;
use Database\Seeders\RolesPermissionsSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Support\FakeFcmSender;
use Tests\TestCase;

class AdminNotificationTest extends TestCase
{
    use RefreshDatabase;

    private FakeFcmSender $fcm;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RolesPermissionsSeeder::class);
        $this->fcm = new FakeFcmSender;
        $this->app->instance(FcmSender::class, $this->fcm);
    }

    private function superAdmin(): Admin
    {
        $admin = Admin::factory()->create();
        $admin->assignRole('super-admin');

        return $admin;
    }

    public function test_compose_returns_metadata(): void
    {
        $this->actingAs($this->superAdmin(), 'web')
            ->getJson('/admin/api/v1/notifications/compose')
            ->assertOk()
            ->assertJsonStructure(['data' => ['targets', 'types', 'clubs', 'governorates']]);
    }

    public function test_broadcast_to_all_fans_out_and_pushes(): void
    {
        $a = User::factory()->create();
        $b = User::factory()->create();
        DeviceToken::factory()->for($a)->create(['token' => 'a1']);
        DeviceToken::factory()->for($b)->create(['token' => 'b1']);

        $this->actingAs($this->superAdmin(), 'web')
            ->postJson('/admin/api/v1/notifications/send', [
                'title_ar' => 'تنبيه', 'title_en' => 'Alert', 'body_ar' => 'مرحبا', 'body_en' => 'Hello', 'target' => 'all',
            ])
            ->assertCreated();

        $batch = NotificationBatch::first();
        $this->assertSame('sent', $batch->status->value);
        $this->assertSame(2, $batch->total_recipients);
        $this->assertSame(2, AppNotification::count());
        $this->assertEqualsCanonicalizing(['a1', 'b1'], $this->fcm->sentTokens);
    }

    public function test_broadcast_to_a_governorate_targets_only_those_users(): void
    {
        User::factory()->create(['governorate' => 'Baghdad']);
        User::factory()->create(['governorate' => 'Basra']);

        $this->actingAs($this->superAdmin(), 'web')
            ->postJson('/admin/api/v1/notifications/send', [
                'title_ar' => 'ت', 'title_en' => 'T', 'body_ar' => 'ب', 'body_en' => 'B',
                'target' => 'governorate', 'target_value' => ['governorate' => 'Baghdad'],
            ])
            ->assertCreated();

        $this->assertSame(1, NotificationBatch::first()->total_recipients);
    }

    public function test_invalid_tokens_are_pruned_after_a_send(): void
    {
        $user = User::factory()->create();
        DeviceToken::factory()->for($user)->create(['token' => 'bad']);
        $this->fcm->invalidTokens = ['bad'];

        $this->actingAs($this->superAdmin(), 'web')
            ->postJson('/admin/api/v1/notifications/send', [
                'title_ar' => 'ت', 'title_en' => 'T', 'body_ar' => 'ب', 'body_en' => 'B', 'target' => 'all',
            ])
            ->assertCreated();

        $this->assertDatabaseHas('device_tokens', ['token' => 'bad', 'is_active' => false]);
    }

    public function test_batches_are_listable(): void
    {
        NotificationBatch::factory()->create();

        $this->actingAs($this->superAdmin(), 'web')
            ->getJson('/admin/api/v1/notifications/batches')
            ->assertOk()
            ->assertJsonCount(1, 'data');
    }

    public function test_notifications_require_permission(): void
    {
        $support = Admin::factory()->create();
        $support->assignRole('support');

        $this->actingAs($support, 'web')
            ->getJson('/admin/api/v1/notifications/compose')
            ->assertStatus(403);
    }
}
