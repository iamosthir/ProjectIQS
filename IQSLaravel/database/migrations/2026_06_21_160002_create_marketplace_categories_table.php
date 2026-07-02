<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('marketplace_categories', function (Blueprint $table) {
            $table->id();
            $table->string('key')->unique();
            $table->foreignId('parent_id')->nullable()->constrained('marketplace_categories')->nullOnDelete();
            $table->string('name_ar');
            $table->string('name_en');
            $table->text('description_ar')->nullable();
            $table->text('description_en')->nullable();
            $table->string('icon_path')->nullable();
            $table->decimal('base_price', 12, 2)->default(0);
            $table->enum('currency', ['IQD', 'USD'])->default('IQD');
            $table->boolean('is_free')->default(false);
            $table->string('pricing_note')->nullable();
            $table->json('field_schema')->nullable();
            $table->boolean('requires_contact_button')->default(true);
            $table->integer('listing_duration_days')->nullable();
            $table->integer('display_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('marketplace_categories');
    }
};
