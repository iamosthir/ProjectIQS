<?php

namespace App\Services\Payment;

use App\Models\Payment;
use App\Support\Enums\PaymentGatewayType;
use App\Support\Jwt;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

/**
 * ZainCash — JWT-signed transaction init → redirect → verify the returned
 * JWT token (§6.2). Confirm exact field names against current onboarding docs.
 *
 * @phpstan-type ZainCashConfig array{merchant_id: ?string, secret: ?string, msisdn: ?string, base_url: string, redirect_url: ?string}
 */
class ZainCashGateway implements PaymentGateway
{
    /**
     * @param  ZainCashConfig  $config
     */
    public function __construct(private readonly array $config) {}

    public function type(): PaymentGatewayType
    {
        return PaymentGatewayType::ZainCash;
    }

    public function initiate(Payment $payment): GatewayRedirect
    {
        $token = Jwt::encode([
            'amount' => (int) round((float) $payment->amount),
            'serviceType' => 'IQS',
            'msisdn' => $this->config['msisdn'],
            'orderId' => $payment->payment_number,
            'redirectUrl' => $this->config['redirect_url'],
            'iat' => time(),
            'exp' => time() + 60 * 60 * 4,
        ], (string) $this->config['secret']);

        $response = Http::asForm()->post($this->url('/transaction/init'), [
            'token' => $token,
            'merchantId' => $this->config['merchant_id'],
            'lang' => 'ar',
        ]);

        $data = $response->json() ?? [];

        if (! $response->successful() || empty($data['id'])) {
            throw new PaymentException('ZainCash init failed: '.($data['err']['msg'] ?? "HTTP {$response->status()}"));
        }

        return new GatewayRedirect(
            redirectUrl: $this->url('/transaction/pay?id='.$data['id']),
            transactionId: (string) $data['id'],
            payload: ['request' => ['orderId' => $payment->payment_number], 'response' => $data],
        );
    }

    public function handleCallback(Request $request): CallbackOutcome
    {
        $token = (string) ($request->input('token') ?? $request->query('token', ''));
        $payload = Jwt::decode($token, (string) $this->config['secret']);

        if ($payload === null) {
            return new CallbackOutcome(signatureValid: false, paid: false, payload: ['token' => $token]);
        }

        $status = (string) ($payload['status'] ?? '');

        return new CallbackOutcome(
            signatureValid: true,
            paid: in_array($status, ['success', 'completed'], true),
            failed: $status === 'failed',
            paymentNumber: $payload['orderid'] ?? $payload['orderId'] ?? null,
            transactionId: isset($payload['id']) ? (string) $payload['id'] : null,
            failureReason: $payload['msg'] ?? null,
            eventType: $status ?: null,
            payload: $payload,
        );
    }

    protected function url(string $path): string
    {
        return rtrim($this->config['base_url'], '/').$path;
    }
}
