<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('fixture_broadcasts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('fixture_id')->constrained()->cascadeOnDelete();
            $table->string('channel_name');
            $table->string('channel_logo_path')->nullable();
            $table->string('stream_url')->nullable();
            $table->string('commentator_name')->nullable();
            $table->integer('display_order')->default(0);
            $table->timestamps();

            $table->index('fixture_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('fixture_broadcasts');
    }
};
