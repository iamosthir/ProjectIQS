<?php

namespace App\Models;

use App\Support\Enums\ClubStatus;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

class Club extends Model
{
    /** @use HasFactory<\Database\Factories\ClubFactory> */
    use HasFactory, SoftDeletes;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'team_id', 'name_ar', 'name_en', 'slug', 'logo_path', 'cover_path',
        'founded_year', 'description_ar', 'description_en', 'governorate', 'city',
        'address', 'latitude', 'longitude', 'phone', 'email', 'website',
        'facebook', 'instagram', 'twitter', 'managed_by', 'is_verified',
        'verified_at', 'status', 'is_active', 'display_order',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'status' => ClubStatus::class,
            'is_verified' => 'boolean',
            'is_active' => 'boolean',
            'verified_at' => 'datetime',
            'founded_year' => 'integer',
            'latitude' => 'decimal:7',
            'longitude' => 'decimal:7',
        ];
    }

    protected static function booted(): void
    {
        static::creating(function (Club $club): void {
            $club->slug ??= Str::slug(($club->name_en ?: $club->name_ar).'-'.Str::random(5));
        });
    }

    /**
     * @return BelongsTo<Team, $this>
     */
    public function team(): BelongsTo
    {
        return $this->belongsTo(Team::class);
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function manager(): BelongsTo
    {
        return $this->belongsTo(User::class, 'managed_by');
    }

    /**
     * @return HasMany<ClubBoardMember, $this>
     */
    public function boardMembers(): HasMany
    {
        return $this->hasMany(ClubBoardMember::class)->orderBy('display_order');
    }

    /**
     * @return HasMany<ClubStaff, $this>
     */
    public function staff(): HasMany
    {
        return $this->hasMany(ClubStaff::class)->orderBy('display_order');
    }

    /**
     * @return HasMany<ClubTitle, $this>
     */
    public function titles(): HasMany
    {
        return $this->hasMany(ClubTitle::class)->orderBy('display_order');
    }

    /**
     * @return HasMany<ClubCaptain, $this>
     */
    public function captains(): HasMany
    {
        return $this->hasMany(ClubCaptain::class)->orderBy('display_order');
    }

    /**
     * @return HasMany<ClubCompetition, $this>
     */
    public function competitions(): HasMany
    {
        return $this->hasMany(ClubCompetition::class)->orderBy('display_order');
    }

    /**
     * @return HasMany<ClubNews, $this>
     */
    public function news(): HasMany
    {
        return $this->hasMany(ClubNews::class);
    }

    /**
     * @return HasMany<ClubVerification, $this>
     */
    public function verifications(): HasMany
    {
        return $this->hasMany(ClubVerification::class);
    }

    /**
     * @return HasMany<FanGroup, $this>
     */
    public function fanGroups(): HasMany
    {
        return $this->hasMany(FanGroup::class);
    }
}
