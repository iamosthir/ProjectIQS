<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Marks a fixture whose events/lineups/statistics were pulled AFTER it
 * finished (the final, complete detail set). The auto-sync details backfill
 * targets finished fixtures where this is still null, so every synced
 * fixture eventually carries its full related data without re-fetching
 * fixtures the provider has nothing for.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('fixtures', function (Blueprint $table) {
            $table->timestamp('details_synced_at')->nullable()->after('last_synced_at');
            $table->index(['status_group', 'details_synced_at']);
        });
    }

    public function down(): void
    {
        Schema::table('fixtures', function (Blueprint $table) {
            $table->dropIndex(['status_group', 'details_synced_at']);
            $table->dropColumn('details_synced_at');
        });
    }
};
