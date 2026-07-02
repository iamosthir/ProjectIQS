<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('notification_batches', function (Blueprint $table) {
            $table->id();
            $table->foreignId('admin_id')->constrained()->cascadeOnDelete();
            $table->string('title_ar');
            $table->string('title_en');
            $table->text('body_ar');
            $table->text('body_en');
            $table->enum('target', ['all', 'club_supporters', 'governorate', 'custom']);
            $table->json('target_value')->nullable();
            $table->enum('type', ['general', 'match', 'goal', 'listing', 'club', 'fan_group', 'payment', 'system'])->default('general');
            $table->enum('action_type', ['none', 'url', 'fixture', 'listing', 'club', 'fan_group'])->default('none');
            $table->string('action_value')->nullable();
            $table->string('image_path')->nullable();
            $table->integer('total_recipients')->default(0);
            $table->integer('sent_count')->default(0);
            $table->integer('failed_count')->default(0);
            $table->enum('status', ['draft', 'queued', 'sending', 'sent', 'failed'])->default('draft');
            $table->timestamp('scheduled_at')->nullable();
            $table->timestamp('sent_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notification_batches');
    }
};
