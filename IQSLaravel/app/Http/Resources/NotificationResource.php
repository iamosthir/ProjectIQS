<?php

namespace App\Http\Resources;

use App\Models\AppNotification;
use App\Support\Localize;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin AppNotification
 */
class NotificationResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => Localize::pick($this->title_ar, $this->title_en),
            'body' => Localize::pick($this->body_ar, $this->body_en),
            'type' => $this->type?->value,
            'action_type' => $this->action_type?->value,
            'action_value' => $this->action_value,
            'image' => $this->image_path,
            'data' => $this->data,
            'is_read' => $this->is_read,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
