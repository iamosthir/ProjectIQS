<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('fixture_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('fixture_id')->constrained()->cascadeOnDelete();
            $table->enum('source', ['api_football', 'manual'])->default('manual');
            $table->foreignId('team_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('player_id')->nullable()->constrained('players')->nullOnDelete();
            $table->foreignId('assist_player_id')->nullable()->constrained('players')->nullOnDelete();
            $table->string('player_name')->nullable();
            $table->string('assist_name')->nullable();
            $table->unsignedTinyInteger('elapsed')->default(0);
            $table->unsignedTinyInteger('extra')->nullable();
            $table->enum('type', [
                'goal', 'card', 'subst', 'var', 'kickoff', 'half_end',
                'penalty', 'match_end', 'match_cancelled', 'match_postponed',
            ]);
            $table->string('detail');
            $table->string('comments')->nullable();
            $table->integer('display_order')->default(0);
            $table->timestamps();

            $table->index('fixture_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('fixture_events');
    }
};
