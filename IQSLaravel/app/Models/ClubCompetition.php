<?php

namespace App\Models;

use App\Support\Enums\ClubCompetitionStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ClubCompetition extends Model
{
    /**
     * @var list<string>
     */
    protected $fillable = [
        'club_id', 'league_id', 'name_ar', 'name_en', 'season', 'status', 'display_order',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return ['status' => ClubCompetitionStatus::class];
    }

    /**
     * @return BelongsTo<Club, $this>
     */
    public function club(): BelongsTo
    {
        return $this->belongsTo(Club::class);
    }

    /**
     * @return BelongsTo<League, $this>
     */
    public function league(): BelongsTo
    {
        return $this->belongsTo(League::class);
    }
}
