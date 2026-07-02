<?php

namespace App\Http\Resources\Admin;

use App\Models\Comment;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Comment
 */
class CommentAdminResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'body' => $this->body,
            'context' => $this->context?->value,
            'commentable_type' => class_basename($this->commentable_type),
            'commentable_id' => $this->commentable_id,
            'parent_id' => $this->parent_id,
            'likes_count' => $this->likes_count,
            'replies_count' => $this->replies_count,
            'is_hidden' => $this->is_hidden,
            'user' => $this->whenLoaded('user', fn () => [
                'id' => $this->user?->id,
                'name' => $this->user?->name,
                'phone' => $this->user?->phone,
            ]),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
