<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FixtureBroadcast extends Model
{
    /** @use HasFactory<\Database\Factories\FixtureBroadcastFactory> */
    use HasFactory;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'fixture_id', 'channel_name', 'channel_logo_path',
        'stream_url', 'commentator_name', 'display_order',
    ];

    /**
     * @return BelongsTo<Fixture, $this>
     */
    public function fixture(): BelongsTo
    {
        return $this->belongsTo(Fixture::class);
    }
}
