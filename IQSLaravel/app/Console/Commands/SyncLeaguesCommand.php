<?php

namespace App\Console\Commands;

use App\Services\ApiFootball\ApiFootballException;
use App\Services\ApiFootball\LeagueSync;
use Illuminate\Console\Command;

class SyncLeaguesCommand extends Command
{
    protected $signature = 'sync:leagues
        {--iraqi : Only Iraqi leagues (shorthand for --country=Iraq)}
        {--country= : Only leagues of this country, as API-Football spells it (e.g. England, World)}';

    protected $description = 'Sync leagues and seasons from API-Football; non-Iraqi leagues import inactive';

    public function handle(LeagueSync $sync): int
    {
        $country = $this->option('country') ?: ($this->option('iraqi') ? 'Iraq' : null);

        try {
            $count = $sync->sync($country);
            $this->info("Synced {$count} leagues.");

            return self::SUCCESS;
        } catch (ApiFootballException $e) {
            $this->error($e->getMessage());

            return self::FAILURE;
        }
    }
}
