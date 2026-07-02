<?php

namespace App\Console\Commands;

use App\Services\ApiFootball\ApiFootballException;
use App\Services\ApiFootball\StandingSync;
use Illuminate\Console\Command;

class SyncStandingsCommand extends Command
{
    protected $signature = 'sync:standings {league : API-Football league id} {season : season year}';

    protected $description = 'Sync standings for a league season';

    public function handle(StandingSync $sync): int
    {
        try {
            $count = $sync->sync((int) $this->argument('league'), (int) $this->argument('season'));
            $this->info("Synced {$count} standing rows.");

            return self::SUCCESS;
        } catch (ApiFootballException $e) {
            $this->error($e->getMessage());

            return self::FAILURE;
        }
    }
}
