<?php

namespace App\Http\Resources\Admin;

use App\Models\MarketplaceCategory;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin MarketplaceCategory
 */
class CategoryAdminResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'key' => $this->key,
            'parent_id' => $this->parent_id,
            'name_ar' => $this->name_ar,
            'name_en' => $this->name_en,
            'description_ar' => $this->description_ar,
            'description_en' => $this->description_en,
            'icon_path' => $this->icon_path,
            'base_price' => (float) $this->base_price,
            'currency' => $this->currency?->value,
            'is_free' => $this->is_free,
            'pricing_note' => $this->pricing_note,
            'field_schema' => $this->field_schema,
            'requires_contact_button' => $this->requires_contact_button,
            'listing_duration_days' => $this->listing_duration_days,
            'display_order' => $this->display_order,
            'is_active' => $this->is_active,
            'listings_count' => $this->whenCounted('listings'),
        ];
    }
}
