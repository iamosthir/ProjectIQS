<?php

namespace Tests\Feature\Api;

use App\Events\PaymentPaid;
use App\Models\Payment;
use App\Models\User;
use App\Support\Enums\PaymentStatus;
use App\Support\Jwt;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Schema;
use Tests\Support\TestPayable;
use Tests\TestCase;

class PaymentTest extends TestCase
{
    use RefreshDatabase;

    private const SECRET = 'test-secret';

    protected function setUp(): void
    {
        parent::setUp();

        Schema::dropIfExists('test_payables');
        Schema::create('test_payables', function ($table): void {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->decimal('amount', 12, 2);
            $table->string('status')->default('pending');
            $table->timestamps();
        });

        config([
            'payments.payables.test' => TestPayable::class,
            'services.zaincash.merchant_id' => 'M1',
            'services.zaincash.secret' => self::SECRET,
            'services.zaincash.msisdn' => '9647700000000',
            'services.zaincash.base_url' => 'https://test.zaincash.iq',
            'services.zaincash.redirect_url' => 'https://app.iqs/return',
        ]);
    }

    private function payable(User $user, float $amount = 20000): TestPayable
    {
        return TestPayable::create(['user_id' => $user->id, 'amount' => $amount]);
    }

    public function test_initiate_zaincash_returns_a_redirect(): void
    {
        Http::fake(['*transaction/init*' => Http::response(['id' => 'TX123'], 200)]);
        $user = User::factory()->create();
        $this->actingAs($user, 'sanctum');

        $payable = $this->payable($user);

        $this->postJson('/api/v1/payments/initiate', [
            'payable_type' => 'test', 'payable_id' => $payable->id, 'gateway' => 'zaincash',
        ])
            ->assertCreated()
            ->assertJsonPath('data.status', 'processing')
            ->assertJsonPath('data.gateway', 'zaincash')
            ->assertJsonFragment(['redirect_url' => 'https://test.zaincash.iq/transaction/pay?id=TX123']);

        $this->assertDatabaseHas('payments', ['gateway_transaction_id' => 'TX123', 'status' => 'processing']);
    }

    public function test_zaincash_callback_marks_paid_and_advances_payable(): void
    {
        Event::fake([PaymentPaid::class]);
        Http::fake(['*transaction/init*' => Http::response(['id' => 'TX123'], 200)]);
        $user = User::factory()->create();
        $this->actingAs($user, 'sanctum');
        $payable = $this->payable($user);

        $number = $this->postJson('/api/v1/payments/initiate', [
            'payable_type' => 'test', 'payable_id' => $payable->id, 'gateway' => 'zaincash',
        ])->json('data.payment_number');

        $token = Jwt::encode(['status' => 'success', 'orderid' => $number, 'id' => 'TX123'], self::SECRET);

        $this->postJson('/api/v1/payments/zaincash/callback', ['token' => $token])->assertOk();

        $payment = Payment::where('payment_number', $number)->first();
        $this->assertSame('paid', $payment->status->value);
        $this->assertNotNull($payment->paid_at);
        $this->assertSame('paid', $payable->fresh()->status); // payable advanced
        $this->assertDatabaseHas('payment_webhooks', ['payment_id' => $payment->id, 'signature_valid' => true, 'processed' => true]);
        Event::assertDispatched(PaymentPaid::class);
    }

    public function test_callback_with_invalid_signature_is_rejected(): void
    {
        $user = User::factory()->create();
        $payable = $this->payable($user);
        $payment = Payment::create([
            'user_id' => $user->id, 'payable_type' => $payable->getMorphClass(), 'payable_id' => $payable->id,
            'payment_number' => Payment::generateNumber(), 'gateway' => 'zaincash', 'amount' => 20000,
            'currency' => 'IQD', 'status' => PaymentStatus::Processing,
        ]);

        $forged = Jwt::encode(['status' => 'success', 'orderid' => $payment->payment_number], 'wrong-secret');

        $this->postJson('/api/v1/payments/zaincash/callback', ['token' => $forged])->assertOk();

        $this->assertSame('processing', $payment->fresh()->status->value); // not paid
        $this->assertDatabaseHas('payment_webhooks', ['signature_valid' => false, 'processed' => false]);
    }

    public function test_paid_callback_is_idempotent_on_replay(): void
    {
        $user = User::factory()->create();
        $payable = $this->payable($user);
        $payment = Payment::create([
            'user_id' => $user->id, 'payable_type' => $payable->getMorphClass(), 'payable_id' => $payable->id,
            'payment_number' => Payment::generateNumber(), 'gateway' => 'zaincash', 'amount' => 20000,
            'currency' => 'IQD', 'status' => PaymentStatus::Processing,
        ]);
        $token = Jwt::encode(['status' => 'success', 'orderid' => $payment->payment_number, 'id' => 'TX9'], self::SECRET);

        $this->postJson('/api/v1/payments/zaincash/callback', ['token' => $token])->assertOk();
        $this->postJson('/api/v1/payments/zaincash/callback', ['token' => $token])->assertOk(); // replay

        $this->assertSame('paid', $payment->fresh()->status->value);
        // Two webhooks logged, payment paid exactly once.
        $this->assertSame(2, $payment->webhooks()->count());
    }

    public function test_status_and_history_are_scoped_to_the_owner(): void
    {
        $user = User::factory()->create();
        $other = User::factory()->create();
        $mine = Payment::factory()->create(['user_id' => $user->id]);
        Payment::factory()->create(['user_id' => $other->id]);

        $this->actingAs($user, 'sanctum');
        $this->getJson('/api/v1/payments')->assertOk()->assertJsonCount(1, 'data');
        $this->getJson("/api/v1/payments/{$mine->payment_number}/status")->assertOk()->assertJsonPath('data.payment_number', $mine->payment_number);
    }

    public function test_initiate_rejects_a_payable_not_owned_by_the_user(): void
    {
        Http::fake();
        $owner = User::factory()->create();
        $payable = $this->payable($owner);

        $this->actingAs(User::factory()->create(), 'sanctum')
            ->postJson('/api/v1/payments/initiate', ['payable_type' => 'test', 'payable_id' => $payable->id, 'gateway' => 'zaincash'])
            ->assertStatus(403);
    }
}
