<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('club_news', function (Blueprint $table) {
            $table->id();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            $table->string('title_ar');
            $table->string('title_en')->nullable();
            $table->string('slug')->unique();
            $table->text('excerpt_ar')->nullable();
            $table->text('excerpt_en')->nullable();
            $table->longText('content_ar');
            $table->longText('content_en')->nullable();
            $table->string('cover_path')->nullable();
            $table->string('author_name')->nullable();
            $table->boolean('is_published')->default(false);
            $table->timestamp('published_at')->nullable();
            $table->integer('views_count')->default(0);
            $table->timestamps();

            $table->index(['club_id', 'is_published']);
        });

        Schema::create('club_news_media', function (Blueprint $table) {
            $table->id();
            $table->foreignId('club_news_id')->constrained('club_news')->cascadeOnDelete();
            $table->enum('type', ['image', 'video']);
            $table->string('path');
            $table->integer('display_order')->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('club_news_media');
        Schema::dropIfExists('club_news');
    }
};
