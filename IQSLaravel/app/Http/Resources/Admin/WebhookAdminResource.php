<?php

namespace App\Http\Resources\Admin;

use App\Models\PaymentWebhook;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin PaymentWebhook
 */
class WebhookAdminResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'gateway' => $this->gateway,
            'payment_id' => $this->payment_id,
            'event_type' => $this->event_type,
            'signature_valid' => $this->signature_valid,
            'processed' => $this->processed,
            'processed_at' => $this->processed_at?->toIso8601String(),
            'ip_address' => $this->ip_address,
            'payload' => $this->payload,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
