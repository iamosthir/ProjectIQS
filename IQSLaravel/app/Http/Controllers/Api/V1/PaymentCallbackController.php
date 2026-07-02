<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\Payment\PaymentService;
use App\Support\Enums\PaymentGatewayType;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Public, signature-verified gateway callbacks (§6.3). Always returns 200 so
 * the provider stops retrying; verification + idempotency live in the service.
 */
class PaymentCallbackController extends Controller
{
    public function __construct(private readonly PaymentService $payments) {}

    public function zaincash(Request $request): JsonResponse
    {
        $this->payments->handleCallback(PaymentGatewayType::ZainCash, $request);

        return $this->ok(null, 'OK');
    }

    public function fib(Request $request): JsonResponse
    {
        $this->payments->handleCallback(PaymentGatewayType::Fib, $request);

        return $this->ok(null, 'OK');
    }
}
