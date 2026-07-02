<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('fixture_lineup_players', function (Blueprint $table): void {
            // Per-row photo so a lineup entry can show an image even when it is
            // not linked to a canonical Player record. Filled by the admin
            // console (uploaded storage-relative path).
            $table->string('photo_path')->nullable()->after('player_name');
        });
    }

    public function down(): void
    {
        Schema::table('fixture_lineup_players', function (Blueprint $table): void {
            $table->dropColumn('photo_path');
        });
    }
};
