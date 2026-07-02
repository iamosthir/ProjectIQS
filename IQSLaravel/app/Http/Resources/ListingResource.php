<?php

namespace App\Http\Resources;

use App\Models\Listing;
use App\Support\Localize;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Listing
 */
class ListingResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $owner = (bool) ($this->is_owner ?? false);

        return [
            'id' => $this->id,
            'title' => Localize::pick($this->title_ar, $this->title_en),
            'slug' => $this->slug,
            'status' => $this->status?->value,
            'category' => [
                'id' => $this->category_id,
                'name' => Localize::pick($this->category?->name_ar, $this->category?->name_en),
            ],
            'full_name' => $this->full_name,
            'photo' => $this->photo_path,
            'age' => $this->age,
            'country' => $this->country,
            'nationality' => $this->nationality,
            'governorate' => $this->governorate,
            'city' => $this->city,
            'attributes' => $this->attributes,
            'cv' => $this->cv_path,
            'is_featured' => $this->is_featured,
            'views_count' => $this->views_count,
            'contacts_count' => $this->contacts_count,
            'contact_available' => $this->contact_available ?? null,
            'media' => ListingMediaResource::collection($this->whenLoaded('media')),
            'store' => $this->whenLoaded('store', fn () => [
                'id' => $this->store?->id,
                'name' => Localize::pick($this->store?->name_ar, $this->store?->name_en),
                'slug' => $this->store?->slug,
                'is_verified' => $this->store?->is_verified,
            ]),
            // Owner-only fields.
            'show_contact' => $this->when($owner, fn () => $this->show_contact),
            'contact' => $this->when($owner, fn () => [
                'phone' => $this->contact_phone,
                'whatsapp' => $this->contact_whatsapp,
                'email' => $this->contact_email,
            ]),
            'rejection_reason' => $this->when($owner, fn () => $this->rejection_reason),
            'published_at' => $this->published_at?->toIso8601String(),
            'expires_at' => $this->expires_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
