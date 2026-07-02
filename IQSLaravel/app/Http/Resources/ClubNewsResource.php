<?php

namespace App\Http\Resources;

use App\Models\ClubNews;
use App\Support\Localize;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin ClubNews
 */
class ClubNewsResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => Localize::pick($this->title_ar, $this->title_en),
            'slug' => $this->slug,
            'excerpt' => Localize::pick($this->excerpt_ar, $this->excerpt_en),
            'cover' => $this->cover_path,
            'author_name' => $this->author_name,
            'views_count' => $this->views_count,
            'published_at' => $this->published_at?->toIso8601String(),
            // Full body only on the article endpoint.
            'content' => $this->when((bool) ($this->with_content ?? false), fn () => Localize::pick($this->content_ar, $this->content_en)),
        ];
    }
}
