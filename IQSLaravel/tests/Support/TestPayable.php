<?php

namespace Tests\Support;

use App\Contracts\Payable;
use App\Models\Payment;
use App\Support\Enums\Currency;
use Illuminate\Database\Eloquent\Model;

/**
 * A throwaway {@see Payable} used by the payment tests in place of Phase 3's
 * Listing. Its table is created on the fly in the test setUp.
 */
class TestPayable extends Model implements Payable
{
    protected $table = 'test_payables';

    protected $guarded = [];

    public function getPaymentAmount(): float
    {
        return (float) $this->amount;
    }

    public function getPaymentCurrency(): Currency
    {
        return Currency::IQD;
    }

    public function getPaymentDescription(): string
    {
        return 'Test payable #'.$this->id;
    }

    public function getPayerId(): int
    {
        return (int) $this->user_id;
    }

    public function onPaymentPaid(Payment $payment): void
    {
        $this->update(['status' => 'paid']);
    }
}
