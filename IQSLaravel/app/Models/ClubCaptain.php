<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ClubCaptain extends Model
{
    /**
     * @var list<string>
     */
    protected $fillable = [
        'club_id', 'name_ar', 'name_en', 'photo_path', 'period_from', 'period_to',
        'description', 'display_order',
    ];

    /**
     * @return BelongsTo<Club, $this>
     */
    public function club(): BelongsTo
    {
        return $this->belongsTo(Club::class);
    }
}
