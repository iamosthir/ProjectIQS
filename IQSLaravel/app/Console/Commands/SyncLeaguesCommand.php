<?php

namespace App\Console\Commands;

use App\Services\ApiFootball\ApiFootballException;
use App\Services\ApiFootball\LeagueSync;
use Illuminate\Console\Command;

class SyncLeaguesCommand extends Command
{
    protected $signature = 'sync:leagues {--iraqi : Only Iraqi leagues}';

    protected $description = 'Sync leagues and seasons from API-Football';

    public function handle(LeagueSync $sync): int
    {
        try {
            $count = $sync->sync((bool) $this->option('iraqi'));
            $this->info("Synced {$count} leagues.");

            return self::SUCCESS;
        } catch (ApiFootballException $e) {
            $this->error($e->getMessage());

            return self::FAILURE;
        }
    }
}
