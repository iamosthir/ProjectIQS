<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('fixture_lineups', function (Blueprint $table) {
            $table->id();
            $table->foreignId('fixture_id')->constrained()->cascadeOnDelete();
            $table->foreignId('team_id')->constrained()->cascadeOnDelete();
            $table->enum('source', ['api_football', 'manual'])->default('manual');
            $table->string('formation')->nullable();
            $table->foreignId('coach_id')->nullable()->constrained()->nullOnDelete();
            $table->string('coach_name')->nullable();
            $table->string('coach_photo')->nullable();
            $table->timestamps();

            $table->unique(['fixture_id', 'team_id']);
        });

        Schema::create('fixture_lineup_players', function (Blueprint $table) {
            $table->id();
            $table->foreignId('fixture_lineup_id')->constrained()->cascadeOnDelete();
            $table->foreignId('player_id')->nullable()->constrained('players')->nullOnDelete();
            $table->string('player_name');
            $table->unsignedTinyInteger('number')->nullable();
            $table->string('position')->nullable(); // G/D/M/F
            $table->string('grid')->nullable();      // "1:1" pitch coords
            $table->boolean('is_starter')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('fixture_lineup_players');
        Schema::dropIfExists('fixture_lineups');
    }
};
