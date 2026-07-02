<?php

namespace App\Services\Payment;

use App\Support\Enums\PaymentGatewayType;

/**
 * Resolves a {@see PaymentGateway} implementation by enum (§6.2).
 */
class PaymentManager
{
    public function gateway(PaymentGatewayType $type): PaymentGateway
    {
        return match ($type) {
            PaymentGatewayType::ZainCash => new ZainCashGateway(config('services.zaincash')),
            PaymentGatewayType::Fib => new FibGateway(config('services.fib')),
            PaymentGatewayType::Manual => new ManualGateway,
        };
    }
}
