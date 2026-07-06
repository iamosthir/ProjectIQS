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
        'live_poll_seconds' => (int) env('API_FOOTBALL_LIVE_POLL_SECONDS', 30),

        /*
         * Automatic sync cadences for the league seasons subscribed via
         * `seasons.auto_sync`. Live scores poll on `live_poll_seconds`
         * above; everything else self-paces inside the every-minute
         * `sync:auto` tick using these intervals. All values are tunable
         * per API plan size — the daily budget guard is the final backstop.
         */
        'auto_sync' => [
            // Full fixtures list of a subscribed season (insert + update).
            'fixtures_minutes' => (int) env('API_FOOTBALL_SYNC_FIXTURES_MINUTES', 15),
            // League table refresh.
            'standings_minutes' => (int) env('API_FOOTBALL_SYNC_STANDINGS_MINUTES', 60),
            // Squads/venues move rarely.
            'teams_minutes' => (int) env('API_FOOTBALL_SYNC_TEAMS_MINUTES', 1440),
            // Scorer charts.
            'top_scorers_minutes' => (int) env('API_FOOTBALL_SYNC_TOP_SCORERS_MINUTES', 360),
            // Pull pre-match lineups for fixtures kicking off within this window…
            'lineup_lookahead_minutes' => (int) env('API_FOOTBALL_SYNC_LINEUP_LOOKAHEAD_MINUTES', 60),
            // …retrying at most once per this interval per fixture.
            'lineup_retry_minutes' => (int) env('API_FOOTBALL_SYNC_LINEUP_RETRY_MINUTES', 15),
            // In-play events/statistics refresh cadence per live fixture.
            'live_details_seconds' => (int) env('API_FOOTBALL_SYNC_LIVE_DETAILS_SECONDS', 60),
        ],
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
