<?php

namespace App\Http\Resources;

use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Payment
 */
class PaymentResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'payment_number' => $this->payment_number,
            'gateway' => $this->gateway?->value,
            'amount' => (float) $this->amount,
            'currency' => $this->currency?->value,
            'status' => $this->status?->value,
            'payable' => [
                'type' => class_basename($this->payable_type),
                'id' => $this->payable_id,
            ],
            // Transient hand-off data, present only on initiate.
            'redirect_url' => $this->redirect_url,
            'qr' => $this->qr,
            'paid_at' => $this->paid_at?->toIso8601String(),
            'expires_at' => $this->expires_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
