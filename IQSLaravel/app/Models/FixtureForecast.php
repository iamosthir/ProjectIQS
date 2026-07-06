<?php

namespace App\Models;

use App\Support\Enums\Source;
use Database\Factories\FixtureForecastFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Editorial/algorithmic prediction for a fixture (API-Football `predictions`).
 * Distinct from {@see FixturePrediction} which stores user votes.
 */
class FixtureForecast extends Model
{
    /** @use HasFactory<FixtureForecastFactory> */
    use HasFactory;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'source', 'fixture_id', 'winner_team_id', 'winner_comment', 'win_or_draw',
        'under_over', 'goals_home', 'goals_away', 'advice',
        'percent_home', 'percent_draw', 'percent_away', 'comparison', 'last_synced_at',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'source' => Source::class,
            'win_or_draw' => 'boolean',
            'comparison' => 'array',
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
    public function winnerTeam(): BelongsTo
    {
        return $this->belongsTo(Team::class, 'winner_team_id');
    }
}
