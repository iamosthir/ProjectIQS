<?php

namespace App\Http\Resources\Admin;

use App\Models\ApiFootballSyncLog;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin ApiFootballSyncLog
 */
class SyncLogResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'endpoint' => $this->endpoint,
            'parameters' => $this->parameters,
            'status' => $this->status,
            'http_status' => $this->http_status,
            'records_processed' => $this->records_processed,
            'requests_remaining' => $this->requests_remaining,
            'error_message' => $this->error_message,
            'duration_ms' => $this->duration_ms,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
