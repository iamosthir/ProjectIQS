<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FanGroupChant extends Model
{
    /** @use HasFactory<\Database\Factories\FanGroupChantFactory> */
    use HasFactory;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'fan_group_id', 'title_ar', 'title_en', 'video_path', 'thumbnail_path', 'lyrics', 'display_order',
    ];

    /**
     * @return BelongsTo<FanGroup, $this>
     */
    public function fanGroup(): BelongsTo
    {
        return $this->belongsTo(FanGroup::class);
    }
}
