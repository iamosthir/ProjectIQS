<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('settings', function (Blueprint $table) {
            $table->id();
            $table->string('group')->index(); // general, payment, match, ...
            $table->string('key');
            $table->text('value')->nullable(); // scalar or JSON
            $table->enum('type', ['string', 'integer', 'boolean', 'json'])->default('string');
            $table->boolean('is_public')->default(false); // exposed via /app/config
            $table->timestamps();

            $table->unique(['group', 'key']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('settings');
    }
};
