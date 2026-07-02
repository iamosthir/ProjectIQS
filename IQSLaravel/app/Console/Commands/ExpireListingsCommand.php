<?php

namespace App\Console\Commands;

use App\Services\Marketplace\ListingService;
use Illuminate\Console\Command;

class ExpireListingsCommand extends Command
{
    protected $signature = 'marketplace:expire-listings';

    protected $description = 'Move published listings past their window to expired';

    public function handle(ListingService $listings): int
    {
        $count = $listings->expireDue();
        $this->info("Expired {$count} listings.");

        return self::SUCCESS;
    }
}
