<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * API-Football `countries` entity. `name`/`code`/`flag` are used as filters by
 * the leagues/teams/venues endpoints, exactly like the upstream API.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('countries', function (Blueprint $table) {
            $table->id();
            $table->enum('source', ['api_football', 'manual'])->default('manual');
            $table->unsignedBigInteger('external_id')->nullable()->index();
            $table->string('name_ar');
            $table->string('name_en');
            // Alpha code, 2-6 chars (FR, GB-ENG…). Nullable: "World" has none.
            $table->string('code', 6)->nullable()->index();
            $table->string('flag_path')->nullable();
            $table->boolean('is_active')->default(true);
            $table->integer('display_order')->default(0);
            $table->boolean('is_locked')->default(false);
            $table->json('external_payload')->nullable();
            $table->timestamp('last_synced_at')->nullable();
            $table->timestamps();

            $table->unique(['source', 'external_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('countries');
    }
};
