<?php

namespace App\Http\Resources\Admin;

use App\Models\Club;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Club
 */
class ClubAdminResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'team_id' => $this->team_id,
            'name_ar' => $this->name_ar,
            'name_en' => $this->name_en,
            'slug' => $this->slug,
            'logo_path' => $this->logo_path,
            'cover_path' => $this->cover_path,
            'founded_year' => $this->founded_year,
            'description_ar' => $this->description_ar,
            'description_en' => $this->description_en,
            'governorate' => $this->governorate,
            'city' => $this->city,
            'address' => $this->address,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'phone' => $this->phone,
            'email' => $this->email,
            'website' => $this->website,
            'facebook' => $this->facebook,
            'instagram' => $this->instagram,
            'twitter' => $this->twitter,
            'managed_by' => $this->managed_by,
            'manager' => $this->whenLoaded('manager', fn () => $this->manager ? [
                'id' => $this->manager->id,
                'name' => $this->manager->name,
                'phone' => $this->manager->phone,
            ] : null),
            'is_verified' => $this->is_verified,
            'status' => $this->status?->value,
            'is_active' => $this->is_active,
            'display_order' => $this->display_order,
            'board' => $this->whenLoaded('boardMembers'),
            'staff' => $this->whenLoaded('staff'),
            'titles' => $this->whenLoaded('titles'),
            'captains' => $this->whenLoaded('captains'),
            'competitions' => $this->whenLoaded('competitions'),
            'news' => $this->whenLoaded('news'),
        ];
    }
}
