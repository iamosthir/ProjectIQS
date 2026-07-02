<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('leagues', function (Blueprint $table) {
            $table->id();
            $table->enum('source', ['api_football', 'manual'])->default('manual');
            $table->unsignedBigInteger('external_id')->nullable()->index();
            $table->string('name_ar');
            $table->string('name_en');
            $table->enum('type', ['league', 'cup'])->default('league');
            $table->string('logo_path')->nullable();
            $table->string('country_name')->nullable();
            $table->string('country_code')->nullable();
            $table->string('country_flag')->nullable();
            $table->boolean('is_iraqi')->default(false);
            $table->enum('category', [
                'premier', 'first_div', 'second_div', 'third_div',
                'nt_senior', 'nt_u21', 'nt_u19', 'nt_u17', 'nt_u16', 'nt_u14', 'other',
            ])->nullable();
            $table->unsignedTinyInteger('tier')->nullable();
            $table->boolean('requires_auth')->default(true);
            $table->boolean('is_featured')->default(false);
            $table->integer('display_order')->default(0);
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
        Schema::dropIfExists('leagues');
    }
};
