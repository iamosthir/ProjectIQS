<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('club_verifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            $table->string('verifiable_type'); // Listing | FanGroup | User
            $table->unsignedBigInteger('verifiable_id');
            $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending');
            $table->enum('method', ['message', 'voice', 'video']);
            $table->text('note')->nullable();
            $table->foreignId('requested_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('reviewed_at')->nullable();
            $table->timestamps();

            $table->index(['verifiable_type', 'verifiable_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('club_verifications');
    }
};
