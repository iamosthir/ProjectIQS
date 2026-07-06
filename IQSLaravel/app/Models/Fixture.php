<?php

namespace App\Models;

use App\Models\Concerns\HasCanonicalSource;
use App\Support\Enums\FixtureStatusGroup;
use App\Support\Enums\MatchWinner;
use Database\Factories\FixtureFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Relations\MorphMany;

class Fixture extends Model
{
    /** @use HasFactory<FixtureFactory> */
    use HasCanonicalSource, HasFactory;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'source', 'external_id', 'league_id', 'season_id', 'round',
        'home_team_id', 'away_team_id', 'venue_id',
        'referee', 'referee_assistant_1', 'referee_assistant_2',
        'referee_fourth_official', 'supervisor',
        'match_datetime', 'timezone', 'status_short', 'status_long',
        'status_group', 'elapsed', 'period_first_at', 'period_second_at', 'status_extra',
        'home_goals', 'away_goals', 'home_ht', 'away_ht', 'home_ft', 'away_ft',
        'home_et', 'away_et', 'home_pen', 'away_pen', 'winner',
        'is_featured', 'has_lineups', 'has_events', 'has_statistics',
        'likes_count', 'comments_count', 'shares_count', 'predictions_count',
        'predict_home_count', 'predict_draw_count', 'predict_away_count',
        'predictions_settled', 'is_locked', 'external_payload', 'last_synced_at',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'match_datetime' => 'datetime',
            'period_first_at' => 'datetime',
            'period_second_at' => 'datetime',
            'status_group' => FixtureStatusGroup::class,
            'winner' => MatchWinner::class,
            'elapsed' => 'integer',
            'status_extra' => 'integer',
            'is_featured' => 'boolean',
            'has_lineups' => 'boolean',
            'has_events' => 'boolean',
            'has_statistics' => 'boolean',
            'predictions_settled' => 'boolean',
        ];
    }

    /**
     * Predictions are only accepted while the match is still scheduled.
     */
    public function isPredictable(): bool
    {
        return $this->status_group === FixtureStatusGroup::Scheduled;
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
    public function homeTeam(): BelongsTo
    {
        return $this->belongsTo(Team::class, 'home_team_id');
    }

    /**
     * @return BelongsTo<Team, $this>
     */
    public function awayTeam(): BelongsTo
    {
        return $this->belongsTo(Team::class, 'away_team_id');
    }

    /**
     * @return BelongsTo<Venue, $this>
     */
    public function venue(): BelongsTo
    {
        return $this->belongsTo(Venue::class);
    }

    /**
     * @return HasMany<FixtureEvent, $this>
     */
    public function events(): HasMany
    {
        return $this->hasMany(FixtureEvent::class)->orderBy('elapsed')->orderBy('display_order');
    }

    /**
     * @return HasMany<FixtureLineup, $this>
     */
    public function lineups(): HasMany
    {
        return $this->hasMany(FixtureLineup::class);
    }

    /**
     * @return HasMany<FixtureNews, $this>
     */
    public function news(): HasMany
    {
        return $this->hasMany(FixtureNews::class)
            ->orderByDesc('published_at')
            ->orderBy('display_order');
    }

    /**
     * @return HasMany<FixtureStatistic, $this>
     */
    public function statistics(): HasMany
    {
        return $this->hasMany(FixtureStatistic::class);
    }

    /**
     * @return HasMany<FixtureBroadcast, $this>
     */
    public function broadcasts(): HasMany
    {
        return $this->hasMany(FixtureBroadcast::class)->orderBy('display_order');
    }

    /**
     * @return HasMany<FixturePrediction, $this>
     */
    public function predictions(): HasMany
    {
        return $this->hasMany(FixturePrediction::class);
    }

    /**
     * @return HasMany<FixturePlayerStatistic, $this>
     */
    public function playerStatistics(): HasMany
    {
        return $this->hasMany(FixturePlayerStatistic::class);
    }

    /**
     * @return HasMany<Injury, $this>
     */
    public function injuries(): HasMany
    {
        return $this->hasMany(Injury::class);
    }

    /**
     * Editorial/algorithmic forecast (API-Football "predictions").
     *
     * @return HasOne<FixtureForecast, $this>
     */
    public function forecast(): HasOne
    {
        return $this->hasOne(FixtureForecast::class);
    }

    /**
     * @return MorphMany<Comment, $this>
     */
    public function comments(): MorphMany
    {
        return $this->morphMany(Comment::class, 'commentable');
    }

    /**
     * @return MorphMany<Like, $this>
     */
    public function likes(): MorphMany
    {
        return $this->morphMany(Like::class, 'likeable');
    }
}
