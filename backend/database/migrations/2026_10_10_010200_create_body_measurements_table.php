<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('body_measurements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->date('measured_at');
            $table->decimal('weight_kg', 6, 2);
            $table->decimal('chest_cm', 6, 2)->nullable();
            $table->decimal('waist_cm', 6, 2)->nullable();
            $table->decimal('hips_cm', 6, 2)->nullable();
            $table->decimal('arm_cm', 6, 2)->nullable();
            $table->decimal('thigh_cm', 6, 2)->nullable();
            $table->timestamps();
            $table->index(['user_id', 'measured_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('body_measurements');
    }
};
