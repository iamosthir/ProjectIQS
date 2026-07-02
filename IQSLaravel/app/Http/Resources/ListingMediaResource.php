<?php

namespace App\Http\Resources;

use App\Models\ListingMedia;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin ListingMedia
 */
class ListingMediaResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'type' => $this->type?->value,
            'url' => $this->path,
            'thumbnail' => $this->thumbnail_path,
            'title' => $this->title,
            'display_order' => $this->display_order,
        ];
    }
}
