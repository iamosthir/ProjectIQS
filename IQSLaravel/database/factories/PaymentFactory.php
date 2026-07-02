<?php

namespace Database\Factories;

use App\Models\Payment;
use App\Models\User;
use App\Support\Enums\Currency;
use App\Support\Enums\PaymentGatewayType;
use App\Support\Enums\PaymentStatus;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Payment>
 */
class PaymentFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $user = User::factory();

        return [
            'user_id' => $user,
            'payable_type' => (new User)->getMorphClass(),
            'payable_id' => $user,
            'payment_number' => Payment::generateNumber(),
            'gateway' => PaymentGatewayType::ZainCash,
            'amount' => 20000,
            'currency' => Currency::IQD,
            'status' => PaymentStatus::Pending,
            'expires_at' => now()->addMinutes(30),
        ];
    }

    public function paid(): static
    {
        return $this->state(fn () => [
            'status' => PaymentStatus::Paid,
            'paid_at' => now(),
            'gateway_transaction_id' => fake()->uuid(),
        ]);
    }
}
