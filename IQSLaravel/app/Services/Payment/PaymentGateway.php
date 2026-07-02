<?php

namespace App\Services\Payment;

use App\Models\Payment;
use App\Support\Enums\PaymentGatewayType;
use Illuminate\Http\Request;

/**
 * A payment provider. Gateway classes are the ONLY place that knows a
 * provider's request/response contract (§6.2).
 */
interface PaymentGateway
{
    public function type(): PaymentGatewayType;

    /**
     * Start the payment with the provider; persist provider refs onto $payment
     * and return where to send the user (redirect/QR).
     */
    public function initiate(Payment $payment): GatewayRedirect;

    /**
     * Parse + verify an incoming callback/IPN request.
     */
    public function handleCallback(Request $request): CallbackOutcome;
}
