<?php

namespace App\Models;

use App\Support\Enums\ListingMediaType;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ListingMedia extends Model
{
    protected $table = 'listing_media';

    /**
     * @var list<string>
     */
    protected $fillable = [
        'listing_id', 'type', 'path', 'thumbnail_path', 'title', 'mime_type', 'size', 'display_order',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'type' => ListingMediaType::class,
            'size' => 'integer',
        ];
    }

    /**
     * @return BelongsTo<Listing, $this>
     */
    public function listing(): BelongsTo
    {
        return $this->belongsTo(Listing::class);
    }
}
