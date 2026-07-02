<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FanGroupDocument extends Model
{
    /**
     * @var list<string>
     */
    protected $fillable = [
        'fan_group_id', 'title_ar', 'title_en', 'path', 'mime_type', 'size', 'display_order',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return ['size' => 'integer'];
    }

    /**
     * @return BelongsTo<FanGroup, $this>
     */
    public function fanGroup(): BelongsTo
    {
        return $this->belongsTo(FanGroup::class);
    }
}
