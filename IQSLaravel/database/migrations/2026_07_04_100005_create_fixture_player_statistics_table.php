<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * API-Football `fixtures/players`: per-match statistics for every player of
 * both teams. Same stat groups as the season table plus the match-scoped
 * games block (minutes, substitute, offsides).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('fixture_player_statistics', function (Blueprint $table) {
            $table->id();
            $table->enum('source', ['api_football', 'manual'])->default('manual');
            $table->foreignId('fixture_id')->constrained()->cascadeOnDelete();
            $table->foreignId('team_id')->constrained()->cascadeOnDelete();
            $table->foreignId('player_id')->nullable()->constrained()->nullOnDelete();
            // Grace column so a row survives a deleted/unknown player.
            $table->string('player_name')->nullable();

            // games
            $table->unsignedSmallInteger('minutes')->nullable();
            $table->unsignedTinyInteger('number')->nullable();
            $table->string('position', 5)->nullable(); // G/D/M/F
            $table->decimal('rating', 4, 2)->nullable();
            $table->boolean('captain')->default(false);
            $table->boolean('substitute')->default(false);

            $table->unsignedTinyInteger('offsides')->nullable();

            // shots
            $table->unsignedSmallInteger('shots_total')->nullable();
            $table->unsignedSmallInteger('shots_on')->nullable();

            // goals
            $table->unsignedSmallInteger('goals_total')->nullable();
            $table->unsignedSmallInteger('goals_conceded')->nullable();
            $table->unsignedSmallInteger('goals_assists')->nullable();
            $table->unsignedSmallInteger('goals_saves')->nullable();

            // passes (accuracy raw string "68%" in the fixture payload)
            $table->unsignedSmallInteger('passes_total')->nullable();
            $table->unsignedSmallInteger('passes_key')->nullable();
            $table->string('passes_accuracy', 10)->nullable();

            // tackles
            $table->unsignedSmallInteger('tackles_total')->nullable();
            $table->unsignedSmallInteger('tackles_blocks')->nullable();
            $table->unsignedSmallInteger('tackles_interceptions')->nullable();

            // duels
            $table->unsignedSmallInteger('duels_total')->nullable();
            $table->unsignedSmallInteger('duels_won')->nullable();

            // dribbles
            $table->unsignedSmallInteger('dribbles_attempts')->nullable();
            $table->unsignedSmallInteger('dribbles_success')->nullable();
            $table->unsignedSmallInteger('dribbles_past')->nullable();

            // fouls
            $table->unsignedSmallInteger('fouls_drawn')->nullable();
            $table->unsignedSmallInteger('fouls_committed')->nullable();

            // cards
            $table->unsignedSmallInteger('cards_yellow')->nullable();
            $table->unsignedSmallInteger('cards_red')->nullable();

            // penalty
            $table->unsignedSmallInteger('penalty_won')->nullable();
            $table->unsignedSmallInteger('penalty_committed')->nullable();
            $table->unsignedSmallInteger('penalty_scored')->nullable();
            $table->unsignedSmallInteger('penalty_missed')->nullable();
            $table->unsignedSmallInteger('penalty_saved')->nullable();

            $table->timestamp('last_synced_at')->nullable();
            $table->timestamps();

            $table->unique(['fixture_id', 'team_id', 'player_id']);
            $table->index(['fixture_id', 'team_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('fixture_player_statistics');
    }
};
