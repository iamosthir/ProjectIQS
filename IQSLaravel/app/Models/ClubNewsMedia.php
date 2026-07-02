<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ClubNewsMedia extends Model
{
    protected $table = 'club_news_media';

    /**
     * @var list<string>
     */
    protected $fillable = [
        'club_news_id', 'type', 'path', 'display_order',
    ];

    /**
     * @return BelongsTo<ClubNews, $this>
     */
    public function news(): BelongsTo
    {
        return $this->belongsTo(ClubNews::class, 'club_news_id');
    }
}
