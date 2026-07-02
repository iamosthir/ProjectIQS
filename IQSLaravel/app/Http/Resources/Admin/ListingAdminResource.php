<?php

namespace App\Http\Resources\Admin;

use App\Http\Resources\ListingMediaResource;
use App\Models\Listing;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Listing
 */
class ListingAdminResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title_ar' => $this->title_ar,
            'title_en' => $this->title_en,
            'slug' => $this->slug,
            'status' => $this->status?->value,
            'category' => $this->whenLoaded('category', fn () => [
                'id' => $this->category?->id,
                'name' => $this->category?->name_en,
                'is_free' => $this->category?->is_free,
            ]),
            'store' => $this->whenLoaded('store', fn () => [
                'id' => $this->store?->id,
                'name' => $this->store?->name_en,
            ]),
            'user' => $this->whenLoaded('user', fn () => [
                'id' => $this->user?->id,
                'name' => $this->user?->name,
                'phone' => $this->user?->phone,
            ]),
            'full_name' => $this->full_name,
            'photo_path' => $this->photo_path,
            'governorate' => $this->governorate,
            'city' => $this->city,
            'age' => $this->age,
            'attributes' => $this->attributes,
            'show_contact' => $this->show_contact,
            'contact' => [
                'phone' => $this->contact_phone,
                'whatsapp' => $this->contact_whatsapp,
                'email' => $this->contact_email,
            ],
            'rejection_reason' => $this->rejection_reason,
            'reviewed_at' => $this->reviewed_at?->toIso8601String(),
            'is_featured' => $this->is_featured,
            'featured_until' => $this->featured_until?->toIso8601String(),
            'views_count' => $this->views_count,
            'contacts_count' => $this->contacts_count,
            'payment' => $this->whenLoaded('payment', fn () => $this->payment ? [
                'id' => $this->payment->id,
                'number' => $this->payment->payment_number,
                'status' => $this->payment->status?->value,
            ] : null),
            'media' => ListingMediaResource::collection($this->whenLoaded('media')),
            'published_at' => $this->published_at?->toIso8601String(),
            'expires_at' => $this->expires_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
