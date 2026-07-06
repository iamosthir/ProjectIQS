<?php

namespace App\Console\Commands;

use App\Jobs\SettleFixturePredictionsJob;
use App\Models\Fixture;
use App\Services\ApiFootball\ApiFootballException;
use App\Services\ApiFootball\FixtureDetailSync;
use App\Services\ApiFootball\FixtureSync;
use App\Services\Notification\MatchNotificationService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Cache;

class SyncLiveCommand extends Command
{
    protected $signature = 'sync:live {--force : Poll even when no synced fixture is in the live window}';

    protected $description = 'Poll live fixtures; refresh in-play details, push match events, pull details on finish, settle predictions';

    public function handle(FixtureSync $sync, FixtureDetailSync $details, MatchNotificationService $notify): int
    {
        // No synced fixture is live or near kickoff → skip the API call
        // entirely so the 30-second cadence never wastes the daily budget
        // on empty days. The window opens from the local fixtures list the
        // auto sync maintains.
        if (! $this->option('force') && ! $this->liveWindowOpen()) {
            $this->info('Live: no fixture in the live window, skipped.');

            return self::SUCCESS;
        }

        try {
            $result = $sync->syncLive();

            foreach ($result['kickoff'] as $fixtureId) {
                if ($fixture = Fixture::find($fixtureId)) {
                    $notify->notifyKickoff($fixture);
                }
            }

            foreach ($result['goals'] as $fixtureId) {
                if ($fixture = Fixture::find($fixtureId)) {
                    $notify->notifyGoal($fixture);
                }
            }

            foreach ($result['finished'] as $fixtureId) {
                $fixture = Fixture::find($fixtureId);

                if ($fixture !== null) {
                    $details->sync($fixture);
                    $notify->notifyFullTime($fixture);
                }

                SettleFixturePredictionsJob::dispatch($fixtureId);
            }

            $inPlay = $this->syncInPlayDetails($details);

            $this->info("Live: {$result['processed']} updated, {$inPlay} in-play detail refreshes, ".count($result['finished']).' finished.');

            return self::SUCCESS;
        } catch (ApiFootballException $e) {
            $this->error($e->getMessage());

            return self::FAILURE;
        }
    }

    /**
     * Whether any API-sourced fixture is currently live or kicking off
     * around now (3h back covers extra time + penalties on delayed status).
     */
    protected function liveWindowOpen(): bool
    {
        return Fixture::query()
            ->apiFootball()
            ->where(fn ($q) => $q
                ->where('status_group', 'live')
                ->orWhere(fn ($w) => $w
                    ->where('status_group', 'scheduled')
                    ->whereBetween('match_datetime', [now()->subHours(3), now()->addMinutes(15)])))
            ->exists();
    }

    /**
     * Keep events/lineups/statistics fresh while a subscribed fixture is in
     * play (they otherwise only arrive at full-time). Throttled per fixture
     * via cache so the cadence is independent of the live-score poll.
     */
    protected function syncInPlayDetails(FixtureDetailSync $details): int
    {
        $seconds = (int) config('services.api_football.auto_sync.live_details_seconds', 60);

        $live = Fixture::query()
            ->apiFootball()
            ->where('status_group', 'live')
            ->whereHas('season', fn ($q) => $q->autoSync())
            ->get();

        $synced = 0;

        foreach ($live as $fixture) {
            if (! Cache::add("auto_sync:live_details:{$fixture->id}", 1, now()->addSeconds($seconds))) {
                continue;
            }

            try {
                $details->sync($fixture);
                $synced++;
            } catch (ApiFootballException $e) {
                $this->warn("In-play details (fixture {$fixture->id}): {$e->getMessage()}");

                if ($e->rateLimited) {
                    break;
                }
            }
        }

        return $synced;
    }
}
