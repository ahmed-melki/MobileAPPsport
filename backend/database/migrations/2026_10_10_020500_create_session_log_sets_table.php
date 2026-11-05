<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('session_log_sets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('session_log_id')->constrained()->cascadeOnDelete();
            $table->string('exercise_slug');
            $table->unsignedInteger('set_number')->default(1);
            $table->unsignedInteger('reps');
            $table->decimal('load_kg', 6, 2)->nullable();
            $table->string('kind');
            $table->string('unit_note')->nullable();
            $table->timestamps();
            $table->foreign('exercise_slug')->references('slug')->on('exercises')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('session_log_sets');
    }
};
