<?php

namespace App\Console\Commands;

use App\Services\ApiFootball\ApiFootballException;
use App\Services\ApiFootball\TeamSync;
use Illuminate\Console\Command;

class SyncTeamsCommand extends Command
{
    protected $signature = 'sync:teams {league : API-Football league id} {season : season year}';

    protected $description = 'Sync teams and venues for a league season';

    public function handle(TeamSync $sync): int
    {
        try {
            $count = $sync->sync((int) $this->argument('league'), (int) $this->argument('season'));
            $this->info("Synced {$count} teams.");

            return self::SUCCESS;
        } catch (ApiFootballException $e) {
            $this->error($e->getMessage());

            return self::FAILURE;
        }
    }
}
