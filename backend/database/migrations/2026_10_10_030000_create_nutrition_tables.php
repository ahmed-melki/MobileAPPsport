<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('foods', function (Blueprint $table) {
            $table->string('slug')->primary();
            $table->string('name');
            $table->string('category');
            $table->string('serving');
            $table->unsignedInteger('calories');
            $table->decimal('protein', 8, 2);
            $table->decimal('carbs', 8, 2);
            $table->decimal('fat', 8, 2);
        });

        Schema::create('recipes', function (Blueprint $table) {
            $table->string('slug')->primary();
            $table->string('name');
            $table->string('subtitle');
            $table->unsignedInteger('calories');
            $table->decimal('protein', 8, 2);
            $table->unsignedInteger('duration');
            $table->string('icon_key')->nullable();
            $table->string('accent_key')->nullable();
        });

        Schema::create('meal_entries', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('food_id')->nullable();
            $table->foreign('food_id')->references('slug')->on('foods')->nullOnDelete();
            $table->string('recipe_slug')->nullable();
            $table->date('date');
            $table->string('type');
            $table->string('name');
            $table->string('time');
            $table->unsignedInteger('calories');
            $table->decimal('protein', 8, 2);
            $table->decimal('carbs', 8, 2);
            $table->decimal('fat', 8, 2);
            $table->timestamps();
            $table->index(['user_id', 'date']);
        });

        Schema::create('nutrition_targets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->unsignedInteger('calories');
            $table->decimal('protein', 8, 2);
            $table->decimal('carbs', 8, 2);
            $table->decimal('fat', 8, 2);
            $table->timestamps();
        });

        Schema::create('user_favorite_recipes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('recipe_slug');
            $table->timestamps();
            $table->unique(['user_id', 'recipe_slug']);
            $table->foreign('recipe_slug')->references('slug')->on('recipes')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_favorite_recipes');
        Schema::dropIfExists('nutrition_targets');
        Schema::dropIfExists('meal_entries');
        Schema::dropIfExists('recipes');
        Schema::dropIfExists('foods');
    }
};
