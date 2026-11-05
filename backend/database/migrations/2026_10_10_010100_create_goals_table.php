<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('goals', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('kind');
            $table->text('detail');
            $table->string('target');
            $table->date('deadline')->nullable();
            $table->decimal('progress', 5, 4)->default(0);
            $table->boolean('is_active')->default(true);
            $table->boolean('is_primary')->default(false);
            $table->timestamps();
            $table->index('user_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('goals');
    }
};
