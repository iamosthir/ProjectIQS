<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Payment window
    |--------------------------------------------------------------------------
    | Minutes a created payment stays valid before it expires.
    */
    'window_minutes' => (int) env('PAYMENT_WINDOW_MINUTES', 30),

    /*
    |--------------------------------------------------------------------------
    | Payable registry
    |--------------------------------------------------------------------------
    | Maps the API-facing `payable_type` key → the Eloquent model class that
    | implements App\Contracts\Payable. The mobile API never exposes class
    | names; it sends a key from this list. Phase 3 registers `listing`.
    */
    'payables' => [
        'listing' => \App\Models\Listing::class,
    ],

];
