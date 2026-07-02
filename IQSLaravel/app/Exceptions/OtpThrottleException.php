<?php

namespace App\Exceptions;

use Exception;

/**
 * Thrown when an OTP is requested again before the per-phone resend cooldown
 * has elapsed. Carries the number of seconds the client must wait so the app
 * can render a countdown. Rendered as HTTP 429 with a `retry_after` body field
 * and a `Retry-After` header (see bootstrap/app.php).
 */
class OtpThrottleException extends Exception
{
    public function __construct(public readonly int $retryAfter, string $message = '')
    {
        parent::__construct($message);
    }
}
