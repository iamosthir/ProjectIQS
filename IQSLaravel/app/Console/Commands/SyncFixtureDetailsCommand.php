<?php

namespace App\Console\Commands;

use App\Models\Fixture;
use App\Services\ApiFootball\ApiFootballException;
use App\Services\ApiFootball\FixtureDetailSync;
use Illuminate\Console\Command;

class SyncFixtureDetailsCommand extends Command
{
    protected $signature = 'sync:fixture-details {fixture : local fixture id}';

    protected $description = 'Sync events, lineups and statistics for a fixture';

    public function handle(FixtureDetailSync $sync): int
    {
        $fixture = Fixture::find($this->argument('fixture'));

        if ($fixture === null) {
            $this->error('Fixture not found.');

            return self::FAILURE;
        }

        try {
            $sync->sync($fixture);
            $this->info('Fixture details synced.');

            return self::SUCCESS;
        } catch (ApiFootballException $e) {
            $this->error($e->getMessage());

            return self::FAILURE;
        }
    }
}
