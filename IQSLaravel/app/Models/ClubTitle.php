<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ClubTitle extends Model
{
    /**
     * @var list<string>
     */
    protected $fillable = [
        'club_id', 'title_ar', 'title_en', 'competition_ar', 'competition_en',
        'season', 'year', 'count', 'image_path', 'display_order',
    ];

    /**
     * @return BelongsTo<Club, $this>
     */
    public function club(): BelongsTo
    {
        return $this->belongsTo(Club::class);
    }
}
