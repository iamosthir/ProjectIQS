<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * API-Football `sidelined`: unavailability periods (injury/suspension) for a
 * player OR a coach — type + start/end dates.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('sidelined', function (Blueprint $table) {
            $table->id();
            $table->enum('source', ['api_football', 'manual'])->default('manual');
            $table->foreignId('player_id')->nullable()->constrained()->cascadeOnDelete();
            $table->foreignId('coach_id')->nullable()->constrained()->cascadeOnDelete();
            $table->string('type');
            $table->date('start_date')->nullable();
            $table->date('end_date')->nullable();
            $table->timestamp('last_synced_at')->nullable();
            $table->timestamps();

            $table->index(['player_id', 'start_date']);
            $table->index(['coach_id', 'start_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sidelined');
    }
};
