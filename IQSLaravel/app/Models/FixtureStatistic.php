<?php

namespace App\Models;

use App\Support\Enums\Source;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FixtureStatistic extends Model
{
    /** @use HasFactory<\Database\Factories\FixtureStatisticFactory> */
    use HasFactory;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'fixture_id', 'team_id', 'source', 'type', 'value', 'value_numeric', 'display_order',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'source' => Source::class,
            'value_numeric' => 'decimal:2',
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
}
