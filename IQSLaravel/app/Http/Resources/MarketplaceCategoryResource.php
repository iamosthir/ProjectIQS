<?php

namespace App\Http\Resources;

use App\Models\MarketplaceCategory;
use App\Support\Localize;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin MarketplaceCategory
 */
class MarketplaceCategoryResource extends JsonResource
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
            'name' => Localize::pick($this->name_ar, $this->name_en),
            'description' => Localize::pick($this->description_ar, $this->description_en),
            'icon' => $this->icon_path,
            'base_price' => (float) $this->base_price,
            'currency' => $this->currency?->value,
            'is_free' => $this->is_free,
            'pricing_note' => $this->pricing_note,
            'field_schema' => $this->field_schema,
            'requires_contact_button' => $this->requires_contact_button,
            'listing_duration_days' => $this->listing_duration_days,
            'children' => MarketplaceCategoryResource::collection($this->whenLoaded('children')),
        ];
    }
}
