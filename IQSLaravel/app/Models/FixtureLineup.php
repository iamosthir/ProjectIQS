<?php

namespace App\Models;

use App\Support\Enums\Source;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class FixtureLineup extends Model
{
    /** @use HasFactory<\Database\Factories\FixtureLineupFactory> */
    use HasFactory;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'fixture_id', 'team_id', 'source', 'formation',
        'coach_id', 'coach_name', 'coach_photo',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'source' => Source::class,
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
     * @return BelongsTo<Coach, $this>
     */
    public function coach(): BelongsTo
    {
        return $this->belongsTo(Coach::class);
    }

    /**
     * @return HasMany<FixtureLineupPlayer, $this>
     */
    public function players(): HasMany
    {
        return $this->hasMany(FixtureLineupPlayer::class);
    }
}
