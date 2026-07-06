<?php

namespace App\Models;

use App\Models\Concerns\HasCanonicalSource;
use Database\Factories\CoachFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Coach extends Model
{
    /** @use HasFactory<CoachFactory> */
    use HasCanonicalSource, HasFactory;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'source', 'external_id', 'name_ar', 'name_en', 'firstname', 'lastname',
        'date_of_birth', 'birth_place', 'birth_country', 'nationality',
        'height', 'weight', 'team_id', 'photo_path',
        'external_payload', 'last_synced_at',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'date_of_birth' => 'date',
        ];
    }

    /**
     * Current team.
     *
     * @return BelongsTo<Team, $this>
     */
    public function team(): BelongsTo
    {
        return $this->belongsTo(Team::class);
    }

    /**
     * @return HasMany<CoachCareer, $this>
     */
    public function careers(): HasMany
    {
        return $this->hasMany(CoachCareer::class)->orderByDesc('start_date');
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
