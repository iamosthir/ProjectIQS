<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class ClubNews extends Model
{
    /** @use HasFactory<\Database\Factories\ClubNewsFactory> */
    use HasFactory;

    protected $table = 'club_news';

    /**
     * @var list<string>
     */
    protected $fillable = [
        'club_id', 'title_ar', 'title_en', 'slug', 'excerpt_ar', 'excerpt_en',
        'content_ar', 'content_en', 'cover_path', 'author_name', 'is_published',
        'published_at', 'views_count',
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

    protected static function booted(): void
    {
        static::creating(function (ClubNews $news): void {
            $news->slug ??= Str::slug(Str::limit($news->title_en ?: $news->title_ar, 40, '')).'-'.Str::random(6);
        });
    }

    /**
     * @return BelongsTo<Club, $this>
     */
    public function club(): BelongsTo
    {
        return $this->belongsTo(Club::class);
    }

    /**
     * @return HasMany<ClubNewsMedia, $this>
     */
    public function media(): HasMany
    {
        return $this->hasMany(ClubNewsMedia::class)->orderBy('display_order');
    }
}
