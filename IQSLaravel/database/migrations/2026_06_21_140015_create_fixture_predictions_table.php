<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('fixture_predictions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('fixture_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('predicted_home_score');
            $table->unsignedTinyInteger('predicted_away_score');
            $table->enum('predicted_outcome', ['home', 'draw', 'away']);
            $table->boolean('is_correct')->nullable();
            $table->boolean('is_exact_score')->nullable();
            $table->integer('likes_count')->default(0);
            $table->timestamps();

            $table->unique(['fixture_id', 'user_id']);
            $table->index(['fixture_id', 'is_correct']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('fixture_predictions');
    }
};
