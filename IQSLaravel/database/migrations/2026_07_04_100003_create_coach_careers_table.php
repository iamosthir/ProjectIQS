<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * API-Football `coachs` → `career[]`: the list of teams a coach has managed
 * with start/end dates (end null = current job).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('coach_careers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('coach_id')->constrained()->cascadeOnDelete();
            $table->foreignId('team_id')->nullable()->constrained()->nullOnDelete();
            // Grace column for stints at teams not present in our DB.
            $table->string('team_name')->nullable();
            $table->date('start_date')->nullable();
            $table->date('end_date')->nullable();
            $table->timestamps();

            $table->index(['coach_id', 'start_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('coach_careers');
    }
};
