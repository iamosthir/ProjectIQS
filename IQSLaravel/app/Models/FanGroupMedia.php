<?php

namespace App\Models;

use App\Support\Enums\FanGroupMediaType;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FanGroupMedia extends Model
{
    /** @use HasFactory<\Database\Factories\FanGroupMediaFactory> */
    use HasFactory;

    protected $table = 'fan_group_media';

    /**
     * @var list<string>
     */
    protected $fillable = [
        'fan_group_id', 'type', 'path', 'thumbnail_path', 'title', 'display_order',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return ['type' => FanGroupMediaType::class];
    }

    /**
     * @return BelongsTo<FanGroup, $this>
     */
    public function fanGroup(): BelongsTo
    {
        return $this->belongsTo(FanGroup::class);
    }
}
