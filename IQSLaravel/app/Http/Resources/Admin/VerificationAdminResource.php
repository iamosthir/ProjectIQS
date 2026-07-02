<?php

namespace App\Http\Resources\Admin;

use App\Models\ClubVerification;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin ClubVerification
 */
class VerificationAdminResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'club' => $this->whenLoaded('club', fn () => [
                'id' => $this->club?->id,
                'name' => $this->club?->name_en,
            ]),
            'verifiable_type' => class_basename($this->verifiable_type),
            'verifiable_id' => $this->verifiable_id,
            'status' => $this->status?->value,
            'method' => $this->method?->value,
            'note' => $this->note,
            'requested_by' => $this->whenLoaded('requestedBy', fn () => [
                'id' => $this->requestedBy?->id,
                'name' => $this->requestedBy?->name,
                'phone' => $this->requestedBy?->phone,
            ]),
            'reviewed_at' => $this->reviewed_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
