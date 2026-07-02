<?php

namespace App\Console\Commands;

use App\Jobs\SettleFixturePredictionsJob;
use App\Models\Fixture;
use App\Services\ApiFootball\ApiFootballException;
use App\Services\ApiFootball\FixtureDetailSync;
use App\Services\ApiFootball\FixtureSync;
use App\Services\Notification\MatchNotificationService;
use Illuminate\Console\Command;

class SyncLiveCommand extends Command
{
    protected $signature = 'sync:live';

    protected $description = 'Poll live fixtures; push match events, pull details on finish, settle predictions';

    public function handle(FixtureSync $sync, FixtureDetailSync $details, MatchNotificationService $notify): int
    {
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

            $this->info("Live: {$result['processed']} updated, ".count($result['finished']).' finished.');

            return self::SUCCESS;
        } catch (ApiFootballException $e) {
            $this->error($e->getMessage());

            return self::FAILURE;
        }
    }
}
