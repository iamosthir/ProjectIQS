<?php

namespace App\Services\Payment;

/**
 * The hand-off a gateway returns from initiate(): where to send the user
 * (redirect URL and/or QR) plus the provider transaction reference.
 */
final class GatewayRedirect
{
    /**
     * @param  array<string, mixed>  $payload
     */
    public function __construct(
        public readonly ?string $redirectUrl = null,
        public readonly ?string $qr = null,
        public readonly ?string $transactionId = null,
        public readonly array $payload = [],
    ) {}
}
