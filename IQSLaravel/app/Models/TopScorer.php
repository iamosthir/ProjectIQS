<?php

namespace App\Models;

use App\Support\Enums\Source;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TopScorer extends Model
{
    /** @use HasFactory<\Database\Factories\TopScorerFactory> */
    use HasFactory;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'source', 'league_id', 'season_id', 'player_id', 'player_name',
        'player_photo_path', 'team_id', 'team_name', 'goals', 'assists',
        'penalties', 'rank', 'display_order', 'last_synced_at',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'source' => Source::class,
            'goals' => 'integer',
            'assists' => 'integer',
            'penalties' => 'integer',
            'rank' => 'integer',
            'last_synced_at' => 'datetime',
        ];
    }

    /**
     * @return BelongsTo<League, $this>
     */
    public function league(): BelongsTo
    {
        return $this->belongsTo(League::class);
    }

    /**
     * @return BelongsTo<Season, $this>
     */
    public function season(): BelongsTo
    {
        return $this->belongsTo(Season::class);
    }

    /**
     * @return BelongsTo<Player, $this>
     */
    public function player(): BelongsTo
    {
        return $this->belongsTo(Player::class);
    }

    /**
     * @return BelongsTo<Team, $this>
     */
    public function team(): BelongsTo
    {
        return $this->belongsTo(Team::class);
    }
}
