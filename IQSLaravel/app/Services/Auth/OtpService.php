<?php

namespace App\Services\Auth;

use App\Exceptions\OtpThrottleException;
use App\Models\OtpVerification;
use App\Services\Sms\OtpSender;
use App\Support\Enums\OtpPurpose;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

/**
 * Generates, delivers, and verifies one-time passcodes. Codes are stored
 * hashed, expire, are rate-limited per phone, and lock after N failed
 * attempts (§1.4 / §1.6).
 */
class OtpService
{
    public function __construct(private readonly OtpSender $sender) {}

    /**
     * Issue a fresh OTP for the given phone + purpose, invalidating any prior
     * pending code. Returns the record and the plaintext code (the code is
     * only ever surfaced to the client when config('otp.expose_code') is on).
     *
     * @return array{otp: OtpVerification, code: string}
     */
    public function request(string $phone, OtpPurpose $purpose, ?string $ip = null): array
    {
        $this->enforceCooldown($phone, $purpose);

        // Drop any earlier pending codes for this phone + purpose.
        OtpVerification::query()
            ->where('phone', $phone)
            ->where('purpose', $purpose->value)
            ->whereNull('verified_at')
            ->delete();

        $code = $this->generateCode();

        $otp = OtpVerification::create([
            'phone' => $phone,
            'otp_code' => Hash::make($code),
            'purpose' => $purpose,
            'attempts' => 0,
            'expires_at' => now()->addMinutes((int) config('otp.ttl_minutes')),
            'ip_address' => $ip,
        ]);

        $this->sender->send($phone, $code);

        return ['otp' => $otp, 'code' => $code];
    }

    /**
     * Verify a submitted code. Throws a ValidationException (→ 422) on any
     * failure; returns the consumed OTP record on success.
     */
    public function verify(string $phone, string $code, OtpPurpose $purpose): OtpVerification
    {
        $otp = OtpVerification::query()
            ->where('phone', $phone)
            ->where('purpose', $purpose->value)
            ->whereNull('verified_at')
            ->latest('created_at')
            ->first();

        if ($otp === null || $otp->isExpired()) {
            throw ValidationException::withMessages([
                'otp' => [__('The verification code is invalid or has expired.')],
            ]);
        }

        if ($otp->attempts >= (int) config('otp.max_attempts')) {
            throw ValidationException::withMessages([
                'otp' => [__('Too many attempts. Please request a new code.')],
            ]);
        }

        if (! Hash::check($code, $otp->otp_code)) {
            $otp->increment('attempts');

            throw ValidationException::withMessages([
                'otp' => [__('The verification code is invalid or has expired.')],
            ]);
        }

        $otp->forceFill(['verified_at' => now()])->save();

        return $otp;
    }

    protected function enforceCooldown(string $phone, OtpPurpose $purpose): void
    {
        $cooldown = (int) config('otp.resend_cooldown_seconds');

        if ($cooldown <= 0) {
            return;
        }

        $recent = OtpVerification::query()
            ->where('phone', $phone)
            ->where('purpose', $purpose->value)
            ->whereNull('verified_at')
            ->latest('created_at')
            ->first();

        if ($recent === null || $recent->created_at === null) {
            return;
        }

        $availableAt = $recent->created_at->copy()->addSeconds($cooldown);
        $retryAfter = $availableAt->getTimestamp() - now()->getTimestamp();

        if ($retryAfter > 0) {
            throw new OtpThrottleException(
                $retryAfter,
                __('Please wait :seconds seconds before requesting another code.', ['seconds' => $retryAfter]),
            );
        }
    }

    protected function generateCode(): string
    {
        // Local dev convenience: a fixed, predictable OTP so testers can sign in
        // without an SMS gateway. Only ever applied in the `local` environment —
        // production/staging/testing always get a real random code.
        if (app()->environment('local')) {
            return (string) config('otp.local_code', '123456');
        }

        $length = max(4, (int) config('otp.length'));
        $max = (10 ** $length) - 1;

        return str_pad((string) random_int(0, $max), $length, '0', STR_PAD_LEFT);
    }
}
