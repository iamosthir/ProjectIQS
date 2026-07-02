<?php

namespace App\Models;

use App\Support\Enums\Source;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Standing extends Model
{
    /** @use HasFactory<\Database\Factories\StandingFactory> */
    use HasFactory;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'league_id', 'season_id', 'team_id', 'source', 'group_label',
        'rank', 'points', 'goals_diff', 'played', 'win', 'draw', 'lose',
        'goals_for', 'goals_against',
        'home_played', 'home_win', 'home_draw', 'home_lose', 'home_goals_for', 'home_goals_against',
        'away_played', 'away_win', 'away_draw', 'away_lose', 'away_goals_for', 'away_goals_against',
        'form', 'status', 'description', 'display_order', 'last_synced_at',
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
     * @return BelongsTo<Team, $this>
     */
    public function team(): BelongsTo
    {
        return $this->belongsTo(Team::class);
    }
}
