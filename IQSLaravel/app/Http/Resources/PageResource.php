<?php

namespace App\Http\Resources;

use App\Models\Page;
use App\Support\Localize;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Page
 */
class PageResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'slug' => $this->slug,
            'title' => Localize::pick($this->title_ar, $this->title_en),
            'content' => Localize::pick($this->content_ar, $this->content_en),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
