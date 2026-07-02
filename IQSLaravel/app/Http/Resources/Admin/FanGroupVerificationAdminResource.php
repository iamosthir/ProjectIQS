<?php

namespace App\Http\Resources\Admin;

use App\Models\FanGroupVerification;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin FanGroupVerification
 */
class FanGroupVerificationAdminResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'fan_group' => $this->whenLoaded('fanGroup', fn () => [
                'id' => $this->fanGroup?->id,
                'name' => $this->fanGroup?->name_en,
            ]),
            'user' => $this->whenLoaded('user', fn () => [
                'id' => $this->user?->id,
                'name' => $this->user?->name,
                'phone' => $this->user?->phone,
            ]),
            'status' => $this->status?->value,
            'method' => $this->method?->value,
            'note' => $this->note,
            'reviewed_at' => $this->reviewed_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
