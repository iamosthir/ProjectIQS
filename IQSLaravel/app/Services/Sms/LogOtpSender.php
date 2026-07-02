<?php

namespace App\Services\Sms;

use Illuminate\Support\Facades\Log;

/**
 * Local/CI OTP sender — writes the code to the log instead of sending an SMS.
 */
class LogOtpSender implements OtpSender
{
    public function send(string $phone, string $code): void
    {
        Log::info('OTP issued', ['phone' => $phone, 'code' => $code]);
    }
}
