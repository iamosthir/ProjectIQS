<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * API-Football `transfers`: one row per move — date, type ("Free", "Loan",
 * "€ 25M", "N/A") and the teams in/out.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('transfers', function (Blueprint $table) {
            $table->id();
            $table->enum('source', ['api_football', 'manual'])->default('manual');
            $table->foreignId('player_id')->constrained()->cascadeOnDelete();
            $table->date('transfer_date')->nullable();
            $table->string('type')->nullable();
            $table->foreignId('team_in_id')->nullable()->constrained('teams')->nullOnDelete();
            $table->foreignId('team_out_id')->nullable()->constrained('teams')->nullOnDelete();
            $table->timestamp('last_synced_at')->nullable();
            $table->timestamps();

            $table->index(['player_id', 'transfer_date']);
            $table->index('team_in_id');
            $table->index('team_out_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('transfers');
    }
};
