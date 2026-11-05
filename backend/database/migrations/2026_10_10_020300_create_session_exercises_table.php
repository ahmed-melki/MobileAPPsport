<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('session_exercises', function (Blueprint $table) {
            $table->id();
            $table->string('session_slug');
            $table->string('exercise_slug');
            $table->unsignedInteger('sets');
            $table->unsignedInteger('reps');
            $table->decimal('load_kg', 6, 2)->nullable();
            $table->unsignedInteger('rest_sec');
            $table->string('kind');
            $table->string('unit_note')->nullable();
            $table->foreign('session_slug')->references('slug')->on('workout_sessions')->cascadeOnDelete();
            $table->foreign('exercise_slug')->references('slug')->on('exercises')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('session_exercises');
    }
};
