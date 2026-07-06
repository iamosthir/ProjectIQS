<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * API-Football `predictions`: the *editorial/algorithmic* forecast for a
 * fixture (winner, advice, win percents, under/over, comparison). Named
 * "forecasts" here because `fixture_predictions` is already taken by the
 * user-vote feature — the mobile endpoint still answers on
 * GET /football/predictions to mirror the upstream API.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('fixture_forecasts', function (Blueprint $table) {
            $table->id();
            $table->enum('source', ['api_football', 'manual'])->default('manual');
            $table->foreignId('fixture_id')->unique()->constrained()->cascadeOnDelete();

            $table->foreignId('winner_team_id')->nullable()->constrained('teams')->nullOnDelete();
            $table->string('winner_comment')->nullable();      // "Win or draw"
            $table->boolean('win_or_draw')->default(false);
            $table->string('under_over', 10)->nullable();      // "-2.5" / "+1.5"
            $table->string('goals_home', 10)->nullable();      // "-2.5"
            $table->string('goals_away', 10)->nullable();
            $table->string('advice')->nullable();

            // percent {home,draw,away} — whole percents, rendered as "45%".
            $table->unsignedTinyInteger('percent_home')->nullable();
            $table->unsignedTinyInteger('percent_draw')->nullable();
            $table->unsignedTinyInteger('percent_away')->nullable();

            // comparison {form,att,def,poisson_distribution,h2h,goals,total}.
            $table->json('comparison')->nullable();

            $table->timestamp('last_synced_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('fixture_forecasts');
    }
};
