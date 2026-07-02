<?php

namespace App\Http\Resources\Admin;

use App\Models\FanGroup;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin FanGroup
 */
class FanGroupAdminResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'club_id' => $this->club_id,
            'name_ar' => $this->name_ar,
            'name_en' => $this->name_en,
            'slug' => $this->slug,
            'founded_year' => $this->founded_year,
            'group_logo_path' => $this->group_logo_path,
            'club_logo_path' => $this->club_logo_path,
            'cover_path' => $this->cover_path,
            'description_ar' => $this->description_ar,
            'description_en' => $this->description_en,
            'governorate' => $this->governorate,
            'city' => $this->city,
            'phone' => $this->phone,
            'facebook' => $this->facebook,
            'instagram' => $this->instagram,
            'twitter' => $this->twitter,
            'managed_by' => $this->managed_by,
            'manager' => $this->whenLoaded('manager', fn () => $this->manager ? [
                'id' => $this->manager->id,
                'name' => $this->manager->name,
                'phone' => $this->manager->phone,
            ] : null),
            'is_official' => $this->is_official,
            'is_verified' => $this->is_verified,
            'status' => $this->status?->value,
            'is_active' => $this->is_active,
            'media_count' => $this->whenCounted('media'),
            'chants_count' => $this->whenCounted('chants'),
            'media' => $this->whenLoaded('media'),
            'chants' => $this->whenLoaded('chants'),
            'documents' => $this->whenLoaded('documents'),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
