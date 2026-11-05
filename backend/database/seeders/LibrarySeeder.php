<?php

namespace Database\Seeders;

use App\Support\ExerciseLibrary;
use App\Support\NutritionLibrary;
use App\Support\TrainingCatalog;
use Illuminate\Database\Seeder;

/**
 * Adds/updates the full exercise, food and recipe library without touching users.
 * php artisan db:seed --class=LibrarySeeder
 */
class LibrarySeeder extends Seeder
{
    public function run(): void
    {
        TrainingCatalog::ensureSeeded();
        $exercises = ExerciseLibrary::seed();
        $nutrition = NutritionLibrary::seed();

        $this->command?->info("Exercises: {$exercises} · Foods: {$nutrition['foods']} · Recipes: {$nutrition['recipes']}");
    }
}
