<?php

namespace App\Services\Payment;

/**
 * The result of parsing + verifying an incoming gateway callback. The service
 * locates the payment by `paymentNumber` (our ref) or `transactionId` (the
 * provider's id).
 */
final class CallbackOutcome
{
    /**
     * @param  array<string, mixed>  $payload
     */
    public function __construct(
        public readonly bool $signatureValid,
        public readonly bool $paid,
        public readonly bool $failed = false,
        public readonly ?string $paymentNumber = null,
        public readonly ?string $transactionId = null,
        public readonly ?string $failureReason = null,
        public readonly ?string $eventType = null,
        public readonly array $payload = [],
    ) {}
}
