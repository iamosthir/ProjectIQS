<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('top_scorers', function (Blueprint $table) {
            $table->id();
            $table->enum('source', ['api_football', 'manual'])->default('manual');
            $table->foreignId('league_id')->constrained()->cascadeOnDelete();
            $table->foreignId('season_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('player_id')->nullable()->constrained('players')->nullOnDelete();
            $table->string('player_name');
            $table->string('player_photo_path')->nullable();
            $table->foreignId('team_id')->nullable()->constrained()->nullOnDelete();
            $table->string('team_name')->nullable();
            $table->unsignedSmallInteger('goals')->default(0);
            $table->unsignedSmallInteger('assists')->nullable();
            $table->unsignedSmallInteger('penalties')->nullable();
            $table->unsignedSmallInteger('rank')->nullable();
            $table->integer('display_order')->default(0);
            $table->timestamp('last_synced_at')->nullable();
            $table->timestamps();

            $table->index(['league_id', 'season_id']);
            $table->unique(['league_id', 'season_id', 'player_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('top_scorers');
    }
};
