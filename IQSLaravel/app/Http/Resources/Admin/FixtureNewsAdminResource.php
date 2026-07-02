<?php

namespace App\Http\Resources\Admin;

use App\Models\FixtureNews;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin FixtureNews
 */
class FixtureNewsAdminResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'fixture_id' => $this->fixture_id,
            'title_ar' => $this->title_ar,
            'title_en' => $this->title_en,
            'excerpt_ar' => $this->excerpt_ar,
            'excerpt_en' => $this->excerpt_en,
            'content_ar' => $this->content_ar,
            'content_en' => $this->content_en,
            'cover_path' => $this->cover_path,
            'source' => $this->source,
            'url' => $this->url,
            'is_published' => (bool) $this->is_published,
            'published_at' => $this->published_at?->toIso8601String(),
            'display_order' => $this->display_order,
        ];
    }
}
