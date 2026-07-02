<?php

namespace App\Http\Resources;

use App\Models\Store;
use App\Support\Localize;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Store
 */
class StoreResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => Localize::pick($this->name_ar, $this->name_en),
            'slug' => $this->slug,
            'logo' => $this->logo_path,
            'cover' => $this->cover_path,
            'bio' => Localize::pick($this->bio_ar, $this->bio_en),
            'phone' => $this->phone,
            'whatsapp' => $this->whatsapp,
            'email' => $this->email,
            'governorate' => $this->governorate,
            'city' => $this->city,
            'is_verified' => $this->is_verified,
            'status' => $this->status?->value,
            'listings_count' => $this->whenCounted('listings'),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
