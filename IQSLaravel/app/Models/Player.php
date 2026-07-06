<?php

namespace App\Models;

use App\Models\Concerns\HasCanonicalSource;
use Database\Factories\PlayerFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Player extends Model
{
    /** @use HasFactory<PlayerFactory> */
    use HasCanonicalSource, HasFactory;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'source', 'external_id', 'name_ar', 'name_en', 'firstname', 'lastname',
        'date_of_birth', 'birth_place', 'birth_country', 'nationality',
        'height', 'weight', 'photo_path', 'position', 'number', 'is_injured',
        'external_payload', 'last_synced_at',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'date_of_birth' => 'date',
            'is_injured' => 'boolean',
        ];
    }

    /**
     * @return BelongsToMany<Team, $this>
     */
    public function teams(): BelongsToMany
    {
        return $this->belongsToMany(Team::class, 'team_player')
            ->withPivot(['season_id', 'number', 'position', 'is_active'])
            ->withTimestamps();
    }

    /**
     * Season-level statistics (one row per team × season).
     *
     * @return HasMany<PlayerStatistic, $this>
     */
    public function statistics(): HasMany
    {
        return $this->hasMany(PlayerStatistic::class);
    }

    /**
     * @return HasMany<FixturePlayerStatistic, $this>
     */
    public function fixtureStatistics(): HasMany
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
     * @return HasMany<Transfer, $this>
     */
    public function transfers(): HasMany
    {
        return $this->hasMany(Transfer::class)->orderByDesc('transfer_date');
    }

    /**
     * @return HasMany<Trophy, $this>
     */
    public function trophies(): HasMany
    {
        return $this->hasMany(Trophy::class);
    }

    /**
     * @return HasMany<Sidelined, $this>
     */
    public function sidelined(): HasMany
    {
        return $this->hasMany(Sidelined::class)->orderByDesc('start_date');
    }
}
