<?php

namespace App\Models;

use App\Support\Enums\Source;
use Database\Factories\SeasonFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Season extends Model
{
    /** @use HasFactory<SeasonFactory> */
    use HasFactory;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'league_id', 'source', 'external_id', 'year', 'label',
        'start_date', 'end_date', 'is_current', 'coverage',
        'auto_sync', 'fixtures_synced_at', 'standings_synced_at',
        'teams_synced_at', 'top_scorers_synced_at',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'source' => Source::class,
            'year' => 'integer',
            'start_date' => 'date',
            'end_date' => 'date',
            'is_current' => 'boolean',
            'coverage' => 'array',
            'auto_sync' => 'boolean',
            'fixtures_synced_at' => 'datetime',
            'standings_synced_at' => 'datetime',
            'teams_synced_at' => 'datetime',
            'top_scorers_synced_at' => 'datetime',
        ];
    }

    /**
     * Seasons subscribed to the automatic API-Football sync.
     *
     * @param  Builder<Season>  $query
     */
    public function scopeAutoSync(Builder $query): void
    {
        $query->where('auto_sync', true);
    }

    /**
     * @return BelongsTo<League, $this>
     */
    public function league(): BelongsTo
    {
        return $this->belongsTo(League::class);
    }

    /**
     * @return HasMany<Fixture, $this>
     */
    public function fixtures(): HasMany
    {
        return $this->hasMany(Fixture::class);
    }

    /**
     * @return HasMany<Standing, $this>
     */
    public function standings(): HasMany
    {
        return $this->hasMany(Standing::class);
    }
}
