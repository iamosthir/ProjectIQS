<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('fixtures', function (Blueprint $table) {
            $table->id();
            $table->enum('source', ['api_football', 'manual'])->default('manual');
            $table->unsignedBigInteger('external_id')->nullable()->index();
            $table->foreignId('league_id')->constrained()->cascadeOnDelete();
            $table->foreignId('season_id')->nullable()->constrained()->nullOnDelete();
            $table->string('round')->nullable();
            $table->foreignId('home_team_id')->constrained('teams')->restrictOnDelete();
            $table->foreignId('away_team_id')->constrained('teams')->restrictOnDelete();
            $table->foreignId('venue_id')->nullable()->constrained()->nullOnDelete();

            // Officials (API fills `referee`; the rest are manual-entry only).
            $table->string('referee')->nullable();
            $table->string('referee_assistant_1')->nullable();
            $table->string('referee_assistant_2')->nullable();
            $table->string('referee_fourth_official')->nullable();
            $table->string('supervisor')->nullable();

            $table->dateTime('match_datetime')->index();
            $table->string('timezone')->default('UTC');

            // Raw API status + normalized group (§2.3).
            $table->string('status_short')->default('NS');
            $table->string('status_long')->nullable();
            $table->enum('status_group', ['scheduled', 'live', 'finished', 'postponed', 'cancelled'])->default('scheduled');
            $table->unsignedTinyInteger('elapsed')->nullable();

            // Score breakdown.
            $table->unsignedTinyInteger('home_goals')->nullable();
            $table->unsignedTinyInteger('away_goals')->nullable();
            $table->unsignedTinyInteger('home_ht')->nullable();
            $table->unsignedTinyInteger('away_ht')->nullable();
            $table->unsignedTinyInteger('home_ft')->nullable();
            $table->unsignedTinyInteger('away_ft')->nullable();
            $table->unsignedTinyInteger('home_et')->nullable();
            $table->unsignedTinyInteger('away_et')->nullable();
            $table->unsignedTinyInteger('home_pen')->nullable();
            $table->unsignedTinyInteger('away_pen')->nullable();
            $table->enum('winner', ['home', 'away', 'draw'])->nullable();

            $table->boolean('is_featured')->default(false);
            $table->boolean('has_lineups')->default(false);
            $table->boolean('has_events')->default(false);
            $table->boolean('has_statistics')->default(false);

            // Social + prediction counters (kept in sync by observers).
            $table->integer('likes_count')->default(0);
            $table->integer('comments_count')->default(0);
            $table->integer('shares_count')->default(0);
            $table->integer('predictions_count')->default(0);
            $table->integer('predict_home_count')->default(0);
            $table->integer('predict_draw_count')->default(0);
            $table->integer('predict_away_count')->default(0);
            $table->boolean('predictions_settled')->default(false);

            $table->boolean('is_locked')->default(false);
            $table->json('external_payload')->nullable();
            $table->timestamp('last_synced_at')->nullable();
            $table->timestamps();

            $table->unique(['source', 'external_id']);
            $table->index(['status_group', 'match_datetime']);
            $table->index(['league_id', 'season_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('fixtures');
    }
};
