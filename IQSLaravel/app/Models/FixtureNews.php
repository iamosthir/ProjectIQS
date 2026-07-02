<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FixtureNews extends Model
{
    /** @use HasFactory<\Database\Factories\FixtureNewsFactory> */
    use HasFactory;

    protected $table = 'fixture_news';

    /**
     * @var list<string>
     */
    protected $fillable = [
        'fixture_id', 'title_ar', 'title_en', 'excerpt_ar', 'excerpt_en',
        'content_ar', 'content_en', 'cover_path', 'source', 'url',
        'is_published', 'published_at', 'display_order',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'is_published' => 'boolean',
            'published_at' => 'datetime',
        ];
    }

    /**
     * @return BelongsTo<Fixture, $this>
     */
    public function fixture(): BelongsTo
    {
        return $this->belongsTo(Fixture::class);
    }
}
