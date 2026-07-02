<?php

namespace App\Http\Resources\Admin;

use App\Models\NotificationBatch;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin NotificationBatch
 */
class NotificationBatchResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title_ar' => $this->title_ar,
            'title_en' => $this->title_en,
            'body_ar' => $this->body_ar,
            'body_en' => $this->body_en,
            'target' => $this->target?->value,
            'target_value' => $this->target_value,
            'type' => $this->type?->value,
            'action_type' => $this->action_type?->value,
            'action_value' => $this->action_value,
            'image_path' => $this->image_path,
            'total_recipients' => $this->total_recipients,
            'sent_count' => $this->sent_count,
            'failed_count' => $this->failed_count,
            'status' => $this->status?->value,
            'scheduled_at' => $this->scheduled_at?->toIso8601String(),
            'sent_at' => $this->sent_at?->toIso8601String(),
            'admin' => $this->whenLoaded('admin', fn () => [
                'id' => $this->admin?->id,
                'name' => $this->admin?->name,
            ]),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
