<?php

namespace App\Services\Payment;

use App\Models\Payment;
use App\Support\Enums\PaymentGatewayType;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

/**
 * FIB (First Iraqi Bank) — OAuth client-credentials → create payment (QR /
 * app link) → confirm via the status API on callback (§6.2). Confirm exact
 * endpoints/fields against current FIB onboarding docs during integration.
 *
 * @phpstan-type FibConfig array{client_id: ?string, client_secret: ?string, base_url: string, callback_url: ?string}
 */
class FibGateway implements PaymentGateway
{
    /**
     * @param  FibConfig  $config
     */
    public function __construct(private readonly array $config) {}

    public function type(): PaymentGatewayType
    {
        return PaymentGatewayType::Fib;
    }

    public function initiate(Payment $payment): GatewayRedirect
    {
        $response = Http::withToken($this->accessToken())->post($this->url('/protected/v1/payments'), [
            'monetaryValue' => ['amount' => (string) $payment->amount, 'currency' => $payment->currency->value],
            'statusCallbackUrl' => $this->config['callback_url'],
            'description' => 'IQS '.$payment->payment_number,
        ]);

        $data = $response->json() ?? [];

        if (! $response->successful() || empty($data['paymentId'])) {
            throw new PaymentException("FIB create payment failed: HTTP {$response->status()}");
        }

        return new GatewayRedirect(
            redirectUrl: $data['personalAppLink'] ?? null,
            qr: $data['qrCode'] ?? null,
            transactionId: (string) $data['paymentId'],
            payload: ['response' => $data],
        );
    }

    public function handleCallback(Request $request): CallbackOutcome
    {
        $paymentId = (string) ($request->input('id') ?? $request->query('id', ''));

        if ($paymentId === '') {
            return new CallbackOutcome(signatureValid: false, paid: false);
        }

        $response = Http::withToken($this->accessToken())->get($this->url("/protected/v1/payments/{$paymentId}/status"));
        $data = $response->json() ?? [];
        $status = (string) ($data['status'] ?? '');

        return new CallbackOutcome(
            signatureValid: $response->successful(),
            paid: $status === 'PAID',
            failed: in_array($status, ['DECLINED', 'EXPIRED', 'FAILED'], true),
            transactionId: $paymentId,
            eventType: $status ?: null,
            payload: $data,
        );
    }

    protected function accessToken(): string
    {
        $response = Http::asForm()->post($this->url('/auth/realms/fib-online-shop/protocol/openid-connect/token'), [
            'grant_type' => 'client_credentials',
            'client_id' => $this->config['client_id'],
            'client_secret' => $this->config['client_secret'],
        ]);

        if (! $response->successful() || empty($response['access_token'])) {
            throw new PaymentException('FIB authentication failed.');
        }

        return (string) $response['access_token'];
    }

    protected function url(string $path): string
    {
        return rtrim($this->config['base_url'], '/').$path;
    }
}
