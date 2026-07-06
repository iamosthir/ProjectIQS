<?php

namespace App\Console\Commands;

use App\Services\ApiFootball\AutoSyncService;
use Illuminate\Console\Command;

class SyncAutoCommand extends Command
{
    protected $signature = 'sync:auto';

    protected $description = 'Sync fixtures/standings/teams/top-scorers for every auto-sync league season that is due';

    public function handle(AutoSyncService $sync): int
    {
        $summary = $sync->run();

        $this->info(sprintf(
            'Auto sync: %d fixtures, %d standings, %d teams, %d top scorers, %d lineups.',
            $summary['fixtures'],
            $summary['standings'],
            $summary['teams'],
            $summary['top_scorers'],
            $summary['lineups'],
        ));

        foreach ($summary['errors'] as $error) {
            $this->warn($error);
        }

        return $summary['errors'] === [] ? self::SUCCESS : self::FAILURE;
    }
}
