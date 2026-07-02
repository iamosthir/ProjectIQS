<?php

namespace App\Http\Resources\Admin;

use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Payment
 */
class PaymentAdminResource extends JsonResource
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
            'gateway_transaction_id' => $this->gateway_transaction_id,
            'gateway_reference' => $this->gateway_reference,
            'failure_reason' => $this->failure_reason,
            'user' => $this->whenLoaded('user', fn () => [
                'id' => $this->user?->id,
                'name' => $this->user?->name,
                'phone' => $this->user?->phone,
            ]),
            'paid_at' => $this->paid_at?->toIso8601String(),
            'expires_at' => $this->expires_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
            'webhooks' => WebhookAdminResource::collection($this->whenLoaded('webhooks')),
        ];
    }
}
