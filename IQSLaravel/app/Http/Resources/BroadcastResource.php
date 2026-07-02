<?php

namespace App\Http\Resources;

use App\Models\FixtureBroadcast;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin FixtureBroadcast
 */
class BroadcastResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'channel' => $this->channel_name,
            'logo' => $this->channel_logo_path,
            'stream_url' => $this->stream_url,
            'commentator' => $this->commentator_name,
        ];
    }
}
