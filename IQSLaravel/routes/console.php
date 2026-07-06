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
| The recurring pipeline: `sync:live` polls live scores every 30 seconds
| (skipping the API call when nothing is in the live window) and refreshes
| in-play events/lineups/statistics; `sync:auto` keeps every subscribed
| league season (seasons.auto_sync, toggled from the admin Sync Console)
| fresh — fixtures, standings, teams, top scorers and pre-match lineups —
| self-pacing per tier via services.api_football.auto_sync. One-off manual
| pulls remain available from the Sync Console. Every command self-guards
| against the daily request budget.
|
| Sub-minute schedules need either `php artisan schedule:work` running, or
| the usual every-minute cron on `php artisan schedule:run` (the runner
| stays alive within the minute to fire the 15/30-second tasks).
*/
Schedule::command('sync:leagues --iraqi')->weekly()->withoutOverlapping();

$liveSync = Schedule::command('sync:live')
    ->withoutOverlapping()
    ->runInBackground();

match ((int) config('services.api_football.live_poll_seconds', 30)) {
    15 => $liveSync->everyFifteenSeconds(),
    30 => $liveSync->everyThirtySeconds(),
    default => $liveSync->everyMinute(),
};

Schedule::command('sync:auto')
    ->everyMinute()
    ->withoutOverlapping()
    ->runInBackground();

// Expire published marketplace listings past their window (§3.4).
Schedule::command('marketplace:expire-listings')->daily();
