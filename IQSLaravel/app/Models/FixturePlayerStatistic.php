<?php

namespace App\Models;

use App\Support\Enums\Source;
use Database\Factories\FixturePlayerStatisticFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Per-match player statistics (API-Football `fixtures/players`).
 */
class FixturePlayerStatistic extends Model
{
    /** @use HasFactory<FixturePlayerStatisticFactory> */
    use HasFactory;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'source', 'fixture_id', 'team_id', 'player_id', 'player_name',
        'minutes', 'number', 'position', 'rating', 'captain', 'substitute', 'offsides',
        'shots_total', 'shots_on',
        'goals_total', 'goals_conceded', 'goals_assists', 'goals_saves',
        'passes_total', 'passes_key', 'passes_accuracy',
        'tackles_total', 'tackles_blocks', 'tackles_interceptions',
        'duels_total', 'duels_won',
        'dribbles_attempts', 'dribbles_success', 'dribbles_past',
        'fouls_drawn', 'fouls_committed',
        'cards_yellow', 'cards_red',
        'penalty_won', 'penalty_committed', 'penalty_scored', 'penalty_missed', 'penalty_saved',
        'last_synced_at',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'source' => Source::class,
            'rating' => 'decimal:2',
            'captain' => 'boolean',
            'substitute' => 'boolean',
            'last_synced_at' => 'datetime',
        ];
    }

    /**
     * @return BelongsTo<Fixture, $this>
     */
    public function fixture(): BelongsTo
    {
        return $this->belongsTo(Fixture::class);
    }

    /**
     * @return BelongsTo<Team, $this>
     */
    public function team(): BelongsTo
    {
        return $this->belongsTo(Team::class);
    }

    /**
     * @return BelongsTo<Player, $this>
     */
    public function player(): BelongsTo
    {
        return $this->belongsTo(Player::class);
    }
}
