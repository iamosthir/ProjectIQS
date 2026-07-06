<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * API-Football `players?season=` statistics block: one row per
 * player × team × season (a transferred player gets two rows in a season).
 * Column groups mirror the payload 1:1 — games, substitutes, shots, goals,
 * passes, tackles, duels, dribbles, fouls, cards, penalty.
 *
 * players/topscorers, topassists, topyellowcards and topredcards are ranked
 * queries over this table, exactly like the upstream API derives them.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('player_statistics', function (Blueprint $table) {
            $table->id();
            $table->enum('source', ['api_football', 'manual'])->default('manual');
            $table->foreignId('player_id')->constrained()->cascadeOnDelete();
            $table->foreignId('team_id')->constrained()->cascadeOnDelete();
            $table->foreignId('league_id')->constrained()->cascadeOnDelete();
            $table->foreignId('season_id')->constrained()->cascadeOnDelete();

            // games
            $table->unsignedSmallInteger('appearances')->nullable();
            $table->unsignedSmallInteger('lineups')->nullable();
            $table->unsignedInteger('minutes')->nullable();
            $table->unsignedTinyInteger('number')->nullable();
            $table->string('position')->nullable();
            $table->decimal('rating', 4, 2)->nullable();
            $table->boolean('captain')->default(false);

            // substitutes
            $table->unsignedSmallInteger('substitutes_in')->nullable();
            $table->unsignedSmallInteger('substitutes_out')->nullable();
            $table->unsignedSmallInteger('substitutes_bench')->nullable();

            // shots
            $table->unsignedSmallInteger('shots_total')->nullable();
            $table->unsignedSmallInteger('shots_on')->nullable();

            // goals
            $table->unsignedSmallInteger('goals_total')->nullable();
            $table->unsignedSmallInteger('goals_conceded')->nullable();
            $table->unsignedSmallInteger('goals_assists')->nullable();
            $table->unsignedSmallInteger('goals_saves')->nullable();

            // passes (accuracy = whole percent, as the season payload returns)
            $table->unsignedSmallInteger('passes_total')->nullable();
            $table->unsignedSmallInteger('passes_key')->nullable();
            $table->unsignedTinyInteger('passes_accuracy')->nullable();

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
            $table->unsignedSmallInteger('cards_yellowred')->nullable();
            $table->unsignedSmallInteger('cards_red')->nullable();

            // penalty
            $table->unsignedSmallInteger('penalty_won')->nullable();
            $table->unsignedSmallInteger('penalty_committed')->nullable();
            $table->unsignedSmallInteger('penalty_scored')->nullable();
            $table->unsignedSmallInteger('penalty_missed')->nullable();
            $table->unsignedSmallInteger('penalty_saved')->nullable();

            $table->timestamp('last_synced_at')->nullable();
            $table->timestamps();

            $table->unique(['player_id', 'team_id', 'season_id']);
            $table->index(['league_id', 'season_id', 'goals_total']);
            $table->index(['league_id', 'season_id', 'goals_assists']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('player_statistics');
    }
};
