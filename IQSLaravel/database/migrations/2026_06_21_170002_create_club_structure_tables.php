<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('club_board_members', function (Blueprint $table) {
            $table->id();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            $table->foreignId('parent_id')->nullable()->constrained('club_board_members')->nullOnDelete();
            $table->string('name_ar');
            $table->string('name_en');
            $table->string('position_ar');
            $table->string('position_en');
            $table->string('photo_path')->nullable();
            $table->integer('display_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('club_staff', function (Blueprint $table) {
            $table->id();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            $table->string('name_ar');
            $table->string('name_en');
            $table->string('role_ar');
            $table->string('role_en');
            $table->enum('type', ['coaching', 'technical', 'medical', 'admin']);
            $table->string('photo_path')->nullable();
            $table->text('bio')->nullable();
            $table->integer('display_order')->default(0);
            $table->timestamps();
        });

        Schema::create('club_titles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            $table->string('title_ar');
            $table->string('title_en');
            $table->string('competition_ar')->nullable();
            $table->string('competition_en')->nullable();
            $table->string('season')->nullable();
            $table->unsignedSmallInteger('year')->nullable();
            $table->unsignedSmallInteger('count')->nullable();
            $table->string('image_path')->nullable();
            $table->integer('display_order')->default(0);
            $table->timestamps();
        });

        Schema::create('club_captains', function (Blueprint $table) {
            $table->id();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            $table->string('name_ar');
            $table->string('name_en');
            $table->string('photo_path')->nullable();
            $table->unsignedSmallInteger('period_from')->nullable();
            $table->unsignedSmallInteger('period_to')->nullable();
            $table->text('description')->nullable();
            $table->integer('display_order')->default(0);
            $table->timestamps();
        });

        Schema::create('club_competitions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('club_id')->constrained()->cascadeOnDelete();
            $table->foreignId('league_id')->nullable()->constrained()->nullOnDelete();
            $table->string('name_ar')->nullable();
            $table->string('name_en')->nullable();
            $table->string('season')->nullable();
            $table->enum('status', ['active', 'past'])->default('active');
            $table->integer('display_order')->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('club_competitions');
        Schema::dropIfExists('club_captains');
        Schema::dropIfExists('club_titles');
        Schema::dropIfExists('club_staff');
        Schema::dropIfExists('club_board_members');
    }
};
