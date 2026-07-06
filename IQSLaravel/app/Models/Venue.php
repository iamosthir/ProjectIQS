<?php

namespace App\Models;

use App\Models\Concerns\HasCanonicalSource;
use Database\Factories\VenueFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Venue extends Model
{
    /** @use HasFactory<VenueFactory> */
    use HasCanonicalSource, HasFactory;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'source', 'external_id', 'name_ar', 'name_en', 'address', 'city',
        'country_id', 'country_name', 'capacity', 'surface', 'image_path',
        'latitude', 'longitude', 'external_payload', 'last_synced_at',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'capacity' => 'integer',
            'latitude' => 'decimal:7',
            'longitude' => 'decimal:7',
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
     * @return HasMany<Team, $this>
     */
    public function teams(): HasMany
    {
        return $this->hasMany(Team::class);
    }
}
