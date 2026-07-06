<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * API-Football `trophies`: honours for a player OR a coach. The upstream
 * payload uses plain strings for league/country/season (e.g. "Ligue 1",
 * "France", "2018/2019", place "Winner" | "2nd Place").
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('trophies', function (Blueprint $table) {
            $table->id();
            $table->enum('source', ['api_football', 'manual'])->default('manual');
            $table->foreignId('player_id')->nullable()->constrained()->cascadeOnDelete();
            $table->foreignId('coach_id')->nullable()->constrained()->cascadeOnDelete();
            $table->string('league_name');
            $table->string('country')->nullable();
            $table->string('season')->nullable();
            $table->string('place')->nullable();
            $table->timestamp('last_synced_at')->nullable();
            $table->timestamps();

            $table->index('player_id');
            $table->index('coach_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('trophies');
    }
};
