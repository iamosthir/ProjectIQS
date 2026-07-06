<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Auto-sync selection + per-tier watermarks. A season row with
 * `auto_sync = true` marks its (league, year) pair as an API-Football
 * subscription: the sync:auto scheduler keeps its fixtures, standings,
 * teams and top scorers refreshed on the configured cadences, using the
 * watermark columns to know when each tier last ran.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('seasons', function (Blueprint $table) {
            $table->boolean('auto_sync')->default(false)->after('is_current')->index();
            $table->timestamp('fixtures_synced_at')->nullable()->after('coverage');
            $table->timestamp('standings_synced_at')->nullable()->after('fixtures_synced_at');
            $table->timestamp('teams_synced_at')->nullable()->after('standings_synced_at');
            $table->timestamp('top_scorers_synced_at')->nullable()->after('teams_synced_at');
        });
    }

    public function down(): void
    {
        Schema::table('seasons', function (Blueprint $table) {
            $table->dropColumn([
                'auto_sync',
                'fixtures_synced_at',
                'standings_synced_at',
                'teams_synced_at',
                'top_scorers_synced_at',
            ]);
        });
    }
};
