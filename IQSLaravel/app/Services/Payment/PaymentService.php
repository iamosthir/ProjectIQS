<?php

namespace App\Services\Payment;

use App\Contracts\Payable;
use App\Events\PaymentPaid;
use App\Models\Payment;
use App\Models\PaymentWebhook;
use App\Models\User;
use App\Support\Enums\PaymentGatewayType;
use App\Support\Enums\PaymentStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PaymentService
{
    public function __construct(private readonly PaymentManager $manager) {}

    /**
     * Create a payment for a payable and hand off to the gateway. The returned
     * model carries transient `redirect_url` / `qr` attributes for the client.
     *
     * @param  Model&Payable  $payable
     */
    public function initiate(Model&Payable $payable, PaymentGatewayType $type, User $user): Payment
    {
        $payment = Payment::create([
            'user_id' => $user->id,
            'payable_type' => $payable->getMorphClass(),
            'payable_id' => $payable->getKey(),
            'payment_number' => Payment::generateNumber(),
            'gateway' => $type,
            'amount' => $payable->getPaymentAmount(),
            'currency' => $payable->getPaymentCurrency(),
            'status' => PaymentStatus::Pending,
            'expires_at' => now()->addMinutes((int) config('payments.window_minutes', 30)),
            'metadata' => ['description' => $payable->getPaymentDescription()],
        ]);

        try {
            $redirect = $this->manager->gateway($type)->initiate($payment);
        } catch (PaymentException $e) {
            $payment->update(['status' => PaymentStatus::Failed, 'failure_reason' => $e->getMessage()]);

            throw $e;
        }

        $payment->forceFill([
            'gateway_transaction_id' => $redirect->transactionId,
            'gateway_payload' => $redirect->payload,
            'status' => $type === PaymentGatewayType::Manual ? PaymentStatus::Pending : PaymentStatus::Processing,
        ])->save();

        $payment->setAttribute('redirect_url', $redirect->redirectUrl);
        $payment->setAttribute('qr', $redirect->qr);

        return $payment;
    }

    /**
     * Process an incoming gateway callback: log the webhook, verify, and
     * (idempotently) settle the payment.
     */
    public function handleCallback(PaymentGatewayType $type, Request $request): PaymentWebhook
    {
        $outcome = $this->manager->gateway($type)->handleCallback($request);
        $payment = $this->findPayment($type, $outcome);

        $webhook = PaymentWebhook::create([
            'gateway' => $type->value,
            'payment_id' => $payment?->id,
            'event_type' => $outcome->eventType,
            'payload' => $outcome->payload,
            'headers' => $this->safeHeaders($request),
            'signature_valid' => $outcome->signatureValid,
            'processed' => false,
            'ip_address' => $request->ip(),
        ]);

        // Reject unverified or unmatched callbacks.
        if (! $outcome->signatureValid || $payment === null) {
            return $webhook;
        }

        // Idempotent: a replay of an already-paid payment is a no-op.
        if ($payment->isPaid()) {
            $webhook->update(['processed' => true, 'processed_at' => now()]);

            return $webhook;
        }

        if ($outcome->paid) {
            $this->markPaid($payment, $outcome->transactionId, $outcome->payload);
        } elseif ($outcome->failed) {
            $payment->update(['status' => PaymentStatus::Failed, 'failure_reason' => $outcome->failureReason]);
        }

        $webhook->update(['processed' => true, 'processed_at' => now()]);

        return $webhook;
    }

    /**
     * Mark a payment paid, advance the payable, and fire the PaymentPaid event.
     * Idempotent.
     *
     * @param  array<string, mixed>  $payload
     */
    public function markPaid(Payment $payment, ?string $transactionId = null, array $payload = []): void
    {
        if ($payment->isPaid()) {
            return;
        }

        DB::transaction(function () use ($payment, $transactionId, $payload): void {
            $payment->forceFill([
                'status' => PaymentStatus::Paid,
                'paid_at' => now(),
                'gateway_transaction_id' => $transactionId ?? $payment->gateway_transaction_id,
                'gateway_payload' => array_merge((array) $payment->gateway_payload, ['callback' => $payload]),
            ])->save();

            $payable = $payment->payable;

            if ($payable instanceof Payable) {
                $payable->onPaymentPaid($payment);
            }
        });

        PaymentPaid::dispatch($payment);
    }

    public function refund(Payment $payment): void
    {
        $payment->update(['status' => PaymentStatus::Refunded]);
    }

    protected function findPayment(PaymentGatewayType $type, CallbackOutcome $outcome): ?Payment
    {
        if ($outcome->paymentNumber !== null) {
            $payment = Payment::where('payment_number', $outcome->paymentNumber)->first();

            if ($payment !== null) {
                return $payment;
            }
        }

        if ($outcome->transactionId !== null) {
            return Payment::where('gateway', $type->value)
                ->where('gateway_transaction_id', $outcome->transactionId)
                ->first();
        }

        return null;
    }

    /**
     * @return array<string, mixed>
     */
    protected function safeHeaders(Request $request): array
    {
        return collect($request->headers->all())->except(['cookie', 'authorization'])->toArray();
    }
}
