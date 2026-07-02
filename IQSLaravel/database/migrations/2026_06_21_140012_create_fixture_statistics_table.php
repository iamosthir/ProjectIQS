<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('fixture_statistics', function (Blueprint $table) {
            $table->id();
            $table->foreignId('fixture_id')->constrained()->cascadeOnDelete();
            $table->foreignId('team_id')->constrained()->cascadeOnDelete();
            $table->enum('source', ['api_football', 'manual'])->default('manual');
            $table->string('type'); // "Shots on Goal", "Ball Possession"
            $table->string('value')->nullable(); // raw ("50%")
            $table->decimal('value_numeric', 10, 2)->nullable(); // parsed
            $table->integer('display_order')->default(0);
            $table->timestamps();

            $table->index('fixture_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('fixture_statistics');
    }
};
