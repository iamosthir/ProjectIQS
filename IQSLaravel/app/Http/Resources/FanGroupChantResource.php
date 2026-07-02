<?php

namespace App\Http\Resources;

use App\Models\FanGroupChant;
use App\Support\Localize;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin FanGroupChant
 */
class FanGroupChantResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => Localize::pick($this->title_ar, $this->title_en),
            'video' => $this->video_path,
            'thumbnail' => $this->thumbnail_path,
            'lyrics' => $this->lyrics,
            'display_order' => $this->display_order,
        ];
    }
}
