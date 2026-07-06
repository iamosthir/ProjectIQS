<?php

namespace App\Models;

use App\Support\Enums\Source;
use Database\Factories\SidelinedFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Unavailability period for a player OR a coach (exactly one FK set).
 */
class Sidelined extends Model
{
    /** @use HasFactory<SidelinedFactory> */
    use HasFactory;

    /**
     * @var string
     */
    protected $table = 'sidelined';

    /**
     * @var list<string>
     */
    protected $fillable = [
        'source', 'player_id', 'coach_id', 'type',
        'start_date', 'end_date', 'last_synced_at',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'source' => Source::class,
            'start_date' => 'date',
            'end_date' => 'date',
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
