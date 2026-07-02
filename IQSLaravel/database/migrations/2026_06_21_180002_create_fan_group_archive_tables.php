<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('fan_group_documents', function (Blueprint $table) {
            $table->id();
            $table->foreignId('fan_group_id')->constrained()->cascadeOnDelete();
            $table->string('title_ar')->nullable();
            $table->string('title_en')->nullable();
            $table->string('path');
            $table->string('mime_type')->nullable();
            $table->unsignedBigInteger('size')->nullable();
            $table->integer('display_order')->default(0);
            $table->timestamps();
        });

        // Photo archive (≤100) + video archive (≤30).
        Schema::create('fan_group_media', function (Blueprint $table) {
            $table->id();
            $table->foreignId('fan_group_id')->constrained()->cascadeOnDelete();
            $table->enum('type', ['image', 'video']);
            $table->string('path');
            $table->string('thumbnail_path')->nullable();
            $table->string('title')->nullable();
            $table->integer('display_order')->default(0);
            $table->timestamps();

            $table->index(['fan_group_id', 'type']);
        });

        // Chants archive (≤20, video).
        Schema::create('fan_group_chants', function (Blueprint $table) {
            $table->id();
            $table->foreignId('fan_group_id')->constrained()->cascadeOnDelete();
            $table->string('title_ar')->nullable();
            $table->string('title_en')->nullable();
            $table->string('video_path');
            $table->string('thumbnail_path')->nullable();
            $table->text('lyrics')->nullable();
            $table->integer('display_order')->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('fan_group_chants');
        Schema::dropIfExists('fan_group_media');
        Schema::dropIfExists('fan_group_documents');
    }
};
