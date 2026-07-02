<?php

namespace App\Http\Requests\Api\Auth\Concerns;

use App\Support\Enums\OtpPurpose;

/**
 * Shared phone normalization + OTP purpose resolution for the auth requests.
 */
trait NormalizesIraqiPhone
{
    /**
     * The submitted phone normalized to E.164 (e.g. +9647712345678).
     */
    public function phoneE164(): string
    {
        return phone((string) $this->input('phone'), 'IQ')->formatE164();
    }

    public function otpPurpose(): OtpPurpose
    {
        return OtpPurpose::tryFrom((string) $this->input('purpose', 'login')) ?? OtpPurpose::Login;
    }
}
