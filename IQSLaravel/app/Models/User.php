<?php

namespace App\Models;

use App\Support\Enums\UserGender;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, HasRoles, Notifiable, SoftDeletes;

    /**
     * App-user capability roles live on the `sanctum` guard (§0.4).
     */
    protected string $guard_name = 'sanctum';

    /**
     * @var list<string>
     */
    protected $fillable = [
        'phone',
        'phone_verified_at',
        'name',
        'email',
        'avatar',
        'supported_club_id',
        'supported_team_id',
        'governorate',
        'gender',
        'date_of_birth',
        'locale',
        'is_active',
        'is_banned',
        'banned_reason',
        'registration_completed_at',
        'last_active_at',
    ];

    /**
     * @var list<string>
     */
    protected $hidden = [
        'remember_token',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'phone_verified_at' => 'datetime',
            'date_of_birth' => 'date',
            'registration_completed_at' => 'datetime',
            'last_active_at' => 'datetime',
            'is_active' => 'boolean',
            'is_banned' => 'boolean',
            'gender' => UserGender::class,
        ];
    }

    /**
     * Whether the user has completed the post-OTP profile form.
     */
    public function hasCompletedRegistration(): bool
    {
        return $this->registration_completed_at !== null;
    }

    /**
     * @return HasMany<DeviceToken, $this>
     */
    public function deviceTokens(): HasMany
    {
        return $this->hasMany(DeviceToken::class);
    }

    /**
     * @return HasOne<Store, $this>
     */
    public function store(): HasOne
    {
        return $this->hasOne(Store::class);
    }

    /**
     * @return HasMany<Listing, $this>
     */
    public function listings(): HasMany
    {
        return $this->hasMany(Listing::class);
    }

    /**
     * Optional supported club (Phase 4). Soft reference (no DB FK).
     *
     * @return BelongsTo<Club, $this>
     */
    public function supportedClub(): BelongsTo
    {
        return $this->belongsTo(Club::class, 'supported_club_id');
    }

    /**
     * The club this user manages (club-admin), if any.
     *
     * @return HasOne<Club, $this>
     */
    public function managedClub(): HasOne
    {
        return $this->hasOne(Club::class, 'managed_by');
    }

    /**
     * The fan group this user manages (group-admin), if any.
     *
     * @return HasOne<FanGroup, $this>
     */
    public function managedFanGroup(): HasOne
    {
        return $this->hasOne(FanGroup::class, 'managed_by');
    }
}
