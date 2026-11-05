<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('session_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('session_slug')->nullable();
            $table->string('program_slug')->nullable();
            $table->string('session_title');
            $table->string('program_title')->nullable();
            $table->dateTime('completed_at')->nullable();
            $table->date('date')->nullable();
            $table->unsignedInteger('duration_min');
            $table->text('highlight')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('session_logs');
    }
};
