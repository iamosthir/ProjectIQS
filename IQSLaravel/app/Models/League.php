<?php

namespace App\Models;

use App\Models\Concerns\HasCanonicalSource;
use App\Support\Enums\LeagueCategory;
use App\Support\Enums\LeagueType;
use Database\Factories\LeagueFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class League extends Model
{
    /** @use HasFactory<LeagueFactory> */
    use HasCanonicalSource, HasFactory;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'source', 'external_id', 'name_ar', 'name_en', 'type', 'logo_path',
        'country_id', 'country_name', 'country_code', 'country_flag', 'is_iraqi', 'category',
        'tier', 'requires_auth', 'is_featured', 'display_order', 'is_active',
        'is_locked', 'external_payload', 'last_synced_at',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'type' => LeagueType::class,
            'category' => LeagueCategory::class,
            'is_iraqi' => 'boolean',
            'requires_auth' => 'boolean',
            'is_featured' => 'boolean',
            'is_active' => 'boolean',
        ];
    }

    /**
     * @return BelongsTo<Country, $this>
     */
    public function country(): BelongsTo
    {
        return $this->belongsTo(Country::class);
    }

    /**
     * @return HasMany<Season, $this>
     */
    public function seasons(): HasMany
    {
        return $this->hasMany(Season::class);
    }

    /**
     * @return HasOne<Season, $this>
     */
    public function currentSeason(): HasOne
    {
        return $this->hasOne(Season::class)->where('is_current', true);
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

    /**
     * @return HasMany<TopScorer, $this>
     */
    public function topScorers(): HasMany
    {
        return $this->hasMany(TopScorer::class);
    }
}
