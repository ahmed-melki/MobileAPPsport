<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('exercises', function (Blueprint $table) {
            $table->string('slug')->primary();
            $table->string('name');
            $table->string('category');
            $table->string('equipment');
            $table->string('muscles');
            $table->text('cue');
            $table->string('last_perf')->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('exercises');
    }
};
