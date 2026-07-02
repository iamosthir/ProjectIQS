<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('seasons', function (Blueprint $table) {
            $table->id();
            $table->foreignId('league_id')->constrained()->cascadeOnDelete();
            $table->enum('source', ['api_football', 'manual'])->default('manual');
            $table->unsignedBigInteger('external_id')->nullable()->index();
            $table->unsignedSmallInteger('year');
            $table->string('label')->nullable();
            $table->date('start_date')->nullable();
            $table->date('end_date')->nullable();
            $table->boolean('is_current')->default(false);
            $table->json('coverage')->nullable();
            $table->timestamps();

            $table->index(['league_id', 'year']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('seasons');
    }
};
