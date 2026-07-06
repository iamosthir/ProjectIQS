<?php

namespace App\Models;

use App\Support\Enums\Source;
use Database\Factories\TrophyFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Honour won by a player OR a coach (exactly one of the two FKs is set).
 */
class Trophy extends Model
{
    /** @use HasFactory<TrophyFactory> */
    use HasFactory;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'source', 'player_id', 'coach_id', 'league_name', 'country',
        'season', 'place', 'last_synced_at',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'source' => Source::class,
            'last_synced_at' => 'datetime',
        ];
    }

    /**
     * @return BelongsTo<Player, $this>
     */
    public function player(): BelongsTo
    {
        return $this->belongsTo(Player::class);
    }

    /**
     * @return BelongsTo<Coach, $this>
     */
    public function coach(): BelongsTo
    {
        return $this->belongsTo(Coach::class);
    }
}
