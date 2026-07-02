<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('api_football_sync_logs', function (Blueprint $table) {
            $table->id();
            $table->string('endpoint');
            $table->json('parameters')->nullable();
            $table->enum('status', ['success', 'failed', 'rate_limited']);
            $table->unsignedSmallInteger('http_status')->nullable();
            $table->integer('records_processed')->nullable();
            $table->integer('requests_remaining')->nullable();
            $table->text('error_message')->nullable();
            $table->integer('duration_ms')->nullable();
            $table->timestamp('created_at')->nullable();

            $table->index(['endpoint', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('api_football_sync_logs');
    }
};
