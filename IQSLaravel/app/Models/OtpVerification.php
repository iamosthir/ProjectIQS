<?php

namespace App\Models;

use App\Support\Enums\OtpPurpose;
use Illuminate\Database\Eloquent\Model;

class OtpVerification extends Model
{
    public const UPDATED_AT = null;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'phone',
        'otp_code',
        'purpose',
        'attempts',
        'expires_at',
        'verified_at',
        'ip_address',
    ];

    /**
     * @var list<string>
     */
    protected $hidden = [
        'otp_code',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'purpose' => OtpPurpose::class,
            'attempts' => 'integer',
            'expires_at' => 'datetime',
            'verified_at' => 'datetime',
        ];
    }

    public function isExpired(): bool
    {
        return $this->expires_at->isPast();
    }

    public function isVerified(): bool
    {
        return $this->verified_at !== null;
    }
}
