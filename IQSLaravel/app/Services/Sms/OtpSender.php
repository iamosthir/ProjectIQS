<?php

namespace App\Services\Sms;

/**
 * Abstraction over the SMS gateway used to deliver one-time passcodes.
 * Swap the bound implementation (see config/otp.php `driver`) when an
 * Iraq-capable SMS provider is selected during integration.
 */
interface OtpSender
{
    /**
     * Deliver the given OTP code to the phone number (E.164).
     */
    public function send(string $phone, string $code): void;
}
