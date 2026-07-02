<?php

namespace App\Contracts;

use App\Models\Payment;
use App\Support\Enums\Currency;

/**
 * Anything that can be paid for via the polymorphic payment system (§6).
 * Phase 3's Listing (and future store/club/group fees) implement this.
 */
interface Payable
{
    public function getPaymentAmount(): float;

    public function getPaymentCurrency(): Currency;

    public function getPaymentDescription(): string;

    /**
     * The id of the user who owns / may pay for this entity.
     */
    public function getPayerId(): int;

    /**
     * Hook invoked once a payment for this entity is confirmed paid — advance
     * the entity's own state (e.g. a listing → pending_review).
     */
    public function onPaymentPaid(Payment $payment): void;
}
