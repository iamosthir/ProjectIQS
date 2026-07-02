<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ApiFootballSyncLog extends Model
{
    public const UPDATED_AT = null;

    protected $table = 'api_football_sync_logs';

    /**
     * @var list<string>
     */
    protected $fillable = [
        'endpoint', 'parameters', 'status', 'http_status',
        'records_processed', 'requests_remaining', 'error_message', 'duration_ms',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'parameters' => 'array',
        ];
    }
}
