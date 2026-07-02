<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('app_versions', function (Blueprint $table) {
            $table->id();
            $table->enum('platform', ['android', 'ios']);
            $table->string('version'); // semver
            $table->unsignedInteger('build_number');
            $table->string('min_supported_version');
            $table->boolean('is_force_update')->default(false);
            $table->text('changelog_ar')->nullable();
            $table->text('changelog_en')->nullable();
            $table->string('store_url');
            $table->boolean('is_active')->default(true);
            $table->timestamp('released_at')->nullable();
            $table->timestamps();

            $table->index(['platform', 'is_active']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('app_versions');
    }
};
