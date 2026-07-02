<?php

namespace App\Models;

use App\Support\Enums\DevicePlatform;
use Illuminate\Database\Eloquent\Model;

class AppVersion extends Model
{
    /**
     * @var list<string>
     */
    protected $fillable = [
        'platform',
        'version',
        'build_number',
        'min_supported_version',
        'is_force_update',
        'changelog_ar',
        'changelog_en',
        'store_url',
        'is_active',
        'released_at',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'platform' => DevicePlatform::class,
            'build_number' => 'integer',
            'is_force_update' => 'boolean',
            'is_active' => 'boolean',
            'released_at' => 'datetime',
        ];
    }
}
