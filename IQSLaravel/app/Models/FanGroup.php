<?php

namespace App\Models;

use App\Support\Enums\FanGroupStatus;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

class FanGroup extends Model
{
    /** @use HasFactory<\Database\Factories\FanGroupFactory> */
    use HasFactory, SoftDeletes;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'club_id', 'name_ar', 'name_en', 'slug', 'founded_year', 'club_logo_path',
        'group_logo_path', 'cover_path', 'description_ar', 'description_en',
        'governorate', 'city', 'phone', 'facebook', 'instagram', 'twitter',
        'managed_by', 'is_official', 'is_verified', 'verified_at', 'status',
        'is_active', 'display_order',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'status' => FanGroupStatus::class,
            'is_official' => 'boolean',
            'is_verified' => 'boolean',
            'is_active' => 'boolean',
            'verified_at' => 'datetime',
            'founded_year' => 'integer',
        ];
    }

    protected static function booted(): void
    {
        static::creating(function (FanGroup $group): void {
            $group->slug ??= Str::slug(($group->name_en ?: $group->name_ar).'-'.Str::random(5));
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
     * @return BelongsTo<User, $this>
     */
    public function manager(): BelongsTo
    {
        return $this->belongsTo(User::class, 'managed_by');
    }

    /**
     * @return HasMany<FanGroupDocument, $this>
     */
    public function documents(): HasMany
    {
        return $this->hasMany(FanGroupDocument::class)->orderBy('display_order');
    }

    /**
     * @return HasMany<FanGroupMedia, $this>
     */
    public function media(): HasMany
    {
        return $this->hasMany(FanGroupMedia::class)->orderBy('display_order');
    }

    /**
     * @return HasMany<FanGroupChant, $this>
     */
    public function chants(): HasMany
    {
        return $this->hasMany(FanGroupChant::class)->orderBy('display_order');
    }

    /**
     * @return HasMany<FanGroupVerification, $this>
     */
    public function verifications(): HasMany
    {
        return $this->hasMany(FanGroupVerification::class);
    }
}
