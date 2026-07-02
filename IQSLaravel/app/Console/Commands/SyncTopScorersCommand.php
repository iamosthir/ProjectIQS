<?php

namespace App\Console\Commands;

use App\Services\ApiFootball\ApiFootballException;
use App\Services\ApiFootball\TopScorerSync;
use Illuminate\Console\Command;

class SyncTopScorersCommand extends Command
{
    protected $signature = 'sync:top-scorers {league : API-Football league id} {season : season year}';

    protected $description = 'Sync top scorers for a league season and recompute ranks';

    public function handle(TopScorerSync $sync): int
    {
        try {
            $count = $sync->sync((int) $this->argument('league'), (int) $this->argument('season'));
            $this->info("Synced {$count} top scorers.");

            return self::SUCCESS;
        } catch (ApiFootballException $e) {
            $this->error($e->getMessage());

            return self::FAILURE;
        }
    }
}
