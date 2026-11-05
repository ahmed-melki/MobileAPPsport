<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('workout_sessions', function (Blueprint $table) {
            $table->string('slug')->primary();
            $table->string('program_slug')->nullable();
            $table->string('title');
            $table->unsignedInteger('duration_min');
            $table->string('focus');
            $table->foreign('program_slug')->references('slug')->on('training_programs')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('workout_sessions');
    }
};
