<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('exercises', function (Blueprint $table) {
            $table->string('muscle_group')->nullable()->after('category');
            $table->string('level')->default('beginner')->after('muscle_group');
            $table->string('kind')->default('load')->after('level');
            $table->boolean('at_home')->default(false)->after('kind');
            $table->json('instructions')->nullable()->after('cue');
        });

        Schema::table('foods', function (Blueprint $table) {
            $table->boolean('is_tunisian')->default(false)->after('fat');
        });

        Schema::table('recipes', function (Blueprint $table) {
            $table->decimal('carbs', 8, 2)->default(0)->after('protein');
            $table->decimal('fat', 8, 2)->default(0)->after('carbs');
            $table->string('meal_type')->nullable()->after('duration');
            $table->json('goal_tags')->nullable()->after('meal_type');
            $table->json('ingredients')->nullable()->after('goal_tags');
            $table->json('steps')->nullable()->after('ingredients');
            $table->boolean('is_tunisian')->default(false)->after('steps');
        });
    }

    public function down(): void
    {
        Schema::table('recipes', function (Blueprint $table) {
            $table->dropColumn(['carbs', 'fat', 'meal_type', 'goal_tags', 'ingredients', 'steps', 'is_tunisian']);
        });

        Schema::table('foods', function (Blueprint $table) {
            $table->dropColumn('is_tunisian');
        });

        Schema::table('exercises', function (Blueprint $table) {
            $table->dropColumn(['muscle_group', 'level', 'kind', 'at_home', 'instructions']);
        });
    }
};
