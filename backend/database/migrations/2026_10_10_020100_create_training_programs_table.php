<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('training_programs', function (Blueprint $table) {
            $table->string('slug')->primary();
            $table->string('title');
            $table->string('subtitle');
            $table->unsignedInteger('weeks');
            $table->unsignedInteger('days_per_week');
            $table->string('level');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('training_programs');
    }
};
