<?php

namespace App\Http\Resources\Admin;

use App\Models\FixtureBroadcast;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin FixtureBroadcast
 */
class BroadcastAdminResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'fixture_id' => $this->fixture_id,
            'channel_name' => $this->channel_name,
            'channel_logo_path' => $this->channel_logo_path,
            'stream_url' => $this->stream_url,
            'commentator_name' => $this->commentator_name,
            'display_order' => $this->display_order,
        ];
    }
}
