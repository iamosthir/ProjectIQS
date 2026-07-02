<?php

namespace App\Http\Resources;

use App\Models\FixtureNews;
use App\Support\Localize;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin FixtureNews
 */
class FixtureNewsResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => Localize::pick($this->title_ar, $this->title_en),
            'excerpt' => Localize::pick($this->excerpt_ar, $this->excerpt_en),
            'content' => Localize::pick($this->content_ar, $this->content_en),
            'cover' => $this->cover_path,
            'source' => $this->source,
            'url' => $this->url,
            'published_at' => $this->published_at?->toIso8601String(),
        ];
    }
}
