<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('teams', function (Blueprint $table) {
            $table->id();
            $table->enum('source', ['api_football', 'manual'])->default('manual');
            $table->unsignedBigInteger('external_id')->nullable()->index();
            $table->string('name_ar');
            $table->string('name_en');
            $table->string('short_code')->nullable();
            $table->string('country_name')->nullable();
            $table->unsignedSmallInteger('founded_year')->nullable();
            $table->boolean('is_national')->default(false);
            $table->string('logo_path')->nullable();
            $table->foreignId('venue_id')->nullable()->constrained()->nullOnDelete();
            // FK to clubs is added in Phase 4 (clubs table doesn't exist yet).
            $table->unsignedBigInteger('club_id')->nullable()->index();
            $table->boolean('is_active')->default(true);
            $table->boolean('is_locked')->default(false);
            $table->json('external_payload')->nullable();
            $table->timestamp('last_synced_at')->nullable();
            $table->timestamps();

            $table->unique(['source', 'external_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('teams');
    }
};
