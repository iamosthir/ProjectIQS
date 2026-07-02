<?php

namespace Tests\Feature\Admin;

use App\Models\Admin;
use App\Models\Payment;
use App\Models\PaymentWebhook;
use Database\Seeders\RolesPermissionsSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminPaymentTest extends TestCase
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

    public function test_admin_can_list_payments(): void
    {
        Payment::factory()->count(2)->create();

        $this->actingAs($this->superAdmin(), 'web')
            ->getJson('/admin/api/v1/payments')
            ->assertOk()
            ->assertJsonCount(2, 'data');
    }

    public function test_admin_can_refund_a_paid_payment(): void
    {
        $payment = Payment::factory()->paid()->create();

        $this->actingAs($this->superAdmin(), 'web')
            ->postJson("/admin/api/v1/payments/{$payment->id}/refund")
            ->assertOk()
            ->assertJsonPath('data.status', 'refunded');

        $this->assertDatabaseHas('payments', ['id' => $payment->id, 'status' => 'refunded']);
    }

    public function test_refund_rejects_an_unpaid_payment(): void
    {
        $payment = Payment::factory()->create(); // pending

        $this->actingAs($this->superAdmin(), 'web')
            ->postJson("/admin/api/v1/payments/{$payment->id}/refund")
            ->assertStatus(422);
    }

    public function test_webhook_log_is_listable(): void
    {
        PaymentWebhook::create([
            'gateway' => 'zaincash', 'payload' => ['x' => 1], 'signature_valid' => true, 'processed' => true,
        ]);

        $this->actingAs($this->superAdmin(), 'web')
            ->getJson('/admin/api/v1/payments/webhooks')
            ->assertOk()
            ->assertJsonCount(1, 'data');
    }

    public function test_payments_require_the_manage_payments_permission(): void
    {
        $support = Admin::factory()->create();
        $support->assignRole('support'); // lacks "manage payments"

        $this->actingAs($support, 'web')
            ->getJson('/admin/api/v1/payments')
            ->assertStatus(403);
    }
}
