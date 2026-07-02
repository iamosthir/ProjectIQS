<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

/*
|--------------------------------------------------------------------------
| API-Football sync schedule (§2.4)
|--------------------------------------------------------------------------
| Heavy per-league syncs (teams/fixtures/standings/top-scorers) need a
| league+season and are triggered from the admin Sync Console; the recurring
| jobs below are the always-on ones. Every command self-guards against the
| daily request budget.
*/
Schedule::command('sync:leagues --iraqi')->weekly()->withoutOverlapping();

Schedule::command('sync:live')
    ->everyMinute()
    ->withoutOverlapping()
    ->runInBackground();

// Expire published marketplace listings past their window (§3.4).
Schedule::command('marketplace:expire-listings')->daily();
