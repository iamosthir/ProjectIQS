<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FixtureLineupPlayer extends Model
{
    /**
     * @var list<string>
     */
    protected $fillable = [
        'fixture_lineup_id', 'player_id', 'player_name', 'photo_path',
        'number', 'position', 'grid', 'is_starter',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'number' => 'integer',
            'is_starter' => 'boolean',
        ];
    }

    /**
     * @return BelongsTo<FixtureLineup, $this>
     */
    public function lineup(): BelongsTo
    {
        return $this->belongsTo(FixtureLineup::class, 'fixture_lineup_id');
    }

    /**
     * @return BelongsTo<Player, $this>
     */
    public function player(): BelongsTo
    {
        return $this->belongsTo(Player::class);
    }
}
