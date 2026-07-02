<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('standings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('league_id')->constrained()->cascadeOnDelete();
            $table->foreignId('season_id')->constrained()->cascadeOnDelete();
            $table->foreignId('team_id')->constrained()->cascadeOnDelete();
            $table->enum('source', ['api_football', 'manual'])->default('manual');
            // '' (not null) so the composite unique key works for ungrouped leagues.
            $table->string('group_label')->default('');
            $table->unsignedSmallInteger('rank')->default(0);
            $table->smallInteger('points')->default(0);
            $table->smallInteger('goals_diff')->default(0);

            $table->unsignedSmallInteger('played')->default(0);
            $table->unsignedSmallInteger('win')->default(0);
            $table->unsignedSmallInteger('draw')->default(0);
            $table->unsignedSmallInteger('lose')->default(0);
            $table->smallInteger('goals_for')->default(0);
            $table->smallInteger('goals_against')->default(0);

            // Home/away split records.
            $table->unsignedSmallInteger('home_played')->default(0);
            $table->unsignedSmallInteger('home_win')->default(0);
            $table->unsignedSmallInteger('home_draw')->default(0);
            $table->unsignedSmallInteger('home_lose')->default(0);
            $table->smallInteger('home_goals_for')->default(0);
            $table->smallInteger('home_goals_against')->default(0);
            $table->unsignedSmallInteger('away_played')->default(0);
            $table->unsignedSmallInteger('away_win')->default(0);
            $table->unsignedSmallInteger('away_draw')->default(0);
            $table->unsignedSmallInteger('away_lose')->default(0);
            $table->smallInteger('away_goals_for')->default(0);
            $table->smallInteger('away_goals_against')->default(0);

            $table->string('form')->nullable();
            $table->string('status')->nullable();
            $table->string('description')->nullable();
            $table->integer('display_order')->default(0);
            $table->timestamp('last_synced_at')->nullable();
            $table->timestamps();

            $table->unique(['league_id', 'season_id', 'team_id', 'group_label']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('standings');
    }
};
