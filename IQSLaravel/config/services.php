<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    'api_football' => [
        'key' => env('API_FOOTBALL_KEY'),
        'base_url' => env('API_FOOTBALL_BASE_URL', 'https://v3.football.api-sports.io'),
        'host' => env('API_FOOTBALL_HOST', 'v3.football.api-sports.io'),
        'timezone' => env('API_FOOTBALL_TIMEZONE', 'Asia/Baghdad'),
        'daily_limit' => (int) env('API_FOOTBALL_DAILY_LIMIT', 100),
        'live_poll_seconds' => (int) env('API_FOOTBALL_LIVE_POLL_SECONDS', 60),
    ],

    'zaincash' => [
        'merchant_id' => env('ZAINCASH_MERCHANT_ID'),
        'secret' => env('ZAINCASH_SECRET'),
        'msisdn' => env('ZAINCASH_MSISDN'),
        'base_url' => env('ZAINCASH_BASE_URL', 'https://test.zaincash.iq'),
        'redirect_url' => env('ZAINCASH_REDIRECT_URL'),
    ],

    'fib' => [
        'client_id' => env('FIB_CLIENT_ID'),
        'client_secret' => env('FIB_CLIENT_SECRET'),
        'base_url' => env('FIB_BASE_URL', 'https://fib.stage.fib.iq'),
        'callback_url' => env('FIB_CALLBACK_URL'),
    ],

    'fcm' => [
        // log | kreait
        'driver' => env('FCM_DRIVER', 'log'),
        'project_id' => env('FCM_PROJECT_ID'),
    ],

];
