<?php

namespace App\Models;

use App\Models\Concerns\HasCanonicalSource;
use Database\Factories\CountryFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Country extends Model
{
    /** @use HasFactory<CountryFactory> */
    use HasCanonicalSource, HasFactory;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'source', 'external_id', 'name_ar', 'name_en', 'code', 'flag_path',
        'is_active', 'display_order', 'is_locked', 'external_payload', 'last_synced_at',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
        ];
    }

    /**
     * @return HasMany<League, $this>
     */
    public function leagues(): HasMany
    {
        return $this->hasMany(League::class);
    }

    /**
     * @return HasMany<Team, $this>
     */
    public function teams(): HasMany
    {
        return $this->hasMany(Team::class);
    }

    /**
     * @return HasMany<Venue, $this>
     */
    public function venues(): HasMany
    {
        return $this->hasMany(Venue::class);
    }
}
