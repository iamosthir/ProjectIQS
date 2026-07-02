<?php

return [

    /*
    |--------------------------------------------------------------------------
    | OTP Sender Driver
    |--------------------------------------------------------------------------
    |
    | Which SMS sender implementation to bind to App\Services\Sms\OtpSender.
    | "log" writes the code to the application log (local dev / CI). Add real
    | Iraq-capable gateway drivers during integration.
    |
    */

    'driver' => env('OTP_DRIVER', 'log'),

    /*
    |--------------------------------------------------------------------------
    | Code Generation
    |--------------------------------------------------------------------------
    */

    'length' => (int) env('OTP_LENGTH', 6),
    'ttl_minutes' => (int) env('OTP_TTL_MINUTES', 5),
    'max_attempts' => (int) env('OTP_MAX_ATTEMPTS', 5),

    // Cooldown (seconds) between OTP requests for the same phone.
    'resend_cooldown_seconds' => (int) env('OTP_RESEND_COOLDOWN', 60),

    /*
    |--------------------------------------------------------------------------
    | Fixed Local Code
    |--------------------------------------------------------------------------
    |
    | In the `local` environment every generated OTP is forced to this fixed
    | code so testers can sign in without a real SMS gateway. It is IGNORED in
    | every other environment (production/staging/testing always get a random
    | code). Override with OTP_LOCAL_CODE if needed.
    |
    */

    'local_code' => env('OTP_LOCAL_CODE', '123456'),

    /*
    |--------------------------------------------------------------------------
    | Expose Code In Response
    |--------------------------------------------------------------------------
    |
    | When true, request-otp returns the generated code in the response under
    | `debug_otp`. NEVER enable in production — it exists so local dev and the
    | automated tests can complete the verify step. Defaults to off.
    |
    */

    'expose_code' => (bool) env('OTP_EXPOSE_CODE', false),

];
