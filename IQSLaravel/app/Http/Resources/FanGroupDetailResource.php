<?php

namespace App\Http\Resources;

use App\Models\FanGroup;
use App\Support\Localize;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin FanGroup
 */
class FanGroupDetailResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return array_merge((new FanGroupResource($this->resource))->toArray($request), [
            'description' => Localize::pick($this->description_ar, $this->description_en),
            'contact' => [
                'phone' => $this->phone,
                'facebook' => $this->facebook,
                'instagram' => $this->instagram,
                'twitter' => $this->twitter,
            ],
            'counts' => [
                'photos' => (int) ($this->photos_count ?? 0),
                'videos' => (int) ($this->videos_count ?? 0),
                'chants' => (int) ($this->chants_count ?? 0),
            ],
            'documents' => $this->whenLoaded('documents', fn () => $this->documents->map(fn ($d) => [
                'id' => $d->id,
                'title' => Localize::pick($d->title_ar, $d->title_en),
                'url' => $d->path,
                'mime_type' => $d->mime_type,
            ])),
        ]);
    }
}
