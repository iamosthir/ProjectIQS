<?php

namespace App\Services\Payment;

use App\Models\Payment;
use App\Support\Enums\PaymentGatewayType;
use Illuminate\Http\Request;

/**
 * Manual gateway — no external provider. The payment stays pending until an
 * admin records it as paid (used for cash / bank-transfer / corrections).
 */
class ManualGateway implements PaymentGateway
{
    public function type(): PaymentGatewayType
    {
        return PaymentGatewayType::Manual;
    }

    public function initiate(Payment $payment): GatewayRedirect
    {
        return new GatewayRedirect;
    }

    public function handleCallback(Request $request): CallbackOutcome
    {
        // No callback for manual payments.
        return new CallbackOutcome(signatureValid: false, paid: false);
    }
}
