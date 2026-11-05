<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_programs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('program_slug');
            $table->string('status')->default('active');
            $table->timestamp('started_at')->nullable();
            $table->timestamp('paused_at')->nullable();
            $table->timestamps();
            $table->foreign('program_slug')->references('slug')->on('training_programs')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_programs');
    }
};
