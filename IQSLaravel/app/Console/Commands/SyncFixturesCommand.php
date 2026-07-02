<?php

namespace App\Console\Commands;

use App\Services\ApiFootball\ApiFootballException;
use App\Services\ApiFootball\FixtureSync;
use Illuminate\Console\Command;

class SyncFixturesCommand extends Command
{
    protected $signature = 'sync:fixtures {league : API-Football league id} {season : season year}';

    protected $description = 'Sync all fixtures for a league season';

    public function handle(FixtureSync $sync): int
    {
        try {
            $count = $sync->syncSeason((int) $this->argument('league'), (int) $this->argument('season'));
            $this->info("Synced {$count} fixtures.");

            return self::SUCCESS;
        } catch (ApiFootballException $e) {
            $this->error($e->getMessage());

            return self::FAILURE;
        }
    }
}
