<?php

namespace App\Http\Resources\Admin;

use App\Models\AppVersion;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin AppVersion
 */
class AppVersionResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'platform' => $this->platform->value,
            'version' => $this->version,
            'build_number' => $this->build_number,
            'min_supported_version' => $this->min_supported_version,
            'is_force_update' => $this->is_force_update,
            'changelog_ar' => $this->changelog_ar,
            'changelog_en' => $this->changelog_en,
            'store_url' => $this->store_url,
            'is_active' => $this->is_active,
            'released_at' => $this->released_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
