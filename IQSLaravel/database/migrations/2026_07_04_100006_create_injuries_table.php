<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * API-Football `injuries`: players not participating in a fixture, filterable
 * by league+season, fixture, team, player and date.
 * `type` is "Missing Fixture" | "Questionable"; `reason` is free text.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('injuries', function (Blueprint $table) {
            $table->id();
            $table->enum('source', ['api_football', 'manual'])->default('manual');
            $table->foreignId('player_id')->constrained()->cascadeOnDelete();
            $table->foreignId('team_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('league_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('season_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('fixture_id')->nullable()->constrained()->nullOnDelete();
            $table->enum('type', ['Missing Fixture', 'Questionable'])->default('Missing Fixture');
            $table->string('reason')->nullable();
            $table->date('date')->nullable();
            $table->timestamp('last_synced_at')->nullable();
            $table->timestamps();

            $table->index(['league_id', 'season_id']);
            $table->index(['team_id', 'date']);
            $table->index('fixture_id');
            $table->index('player_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('injuries');
    }
};
