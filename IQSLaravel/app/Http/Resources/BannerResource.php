<?php

namespace App\Http\Resources;

use App\Models\Banner;
use App\Support\Localize;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Banner
 */
class BannerResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => Localize::pick($this->title_ar, $this->title_en),
            'image' => $this->image_path,
            'action_type' => $this->action_type?->value,
            'action_value' => $this->action_value,
            'placement' => $this->placement?->value,
            'position' => $this->position,
        ];
    }
}
