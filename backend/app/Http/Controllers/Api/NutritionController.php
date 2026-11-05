<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreMealRequest;
use App\Http\Requests\UpdateNutritionTargetRequest;
use App\Http\Resources\FoodResource;
use App\Http\Resources\MealEntryResource;
use App\Http\Resources\NutritionTargetResource;
use App\Http\Resources\RecipeResource;
use App\Models\Food;
use App\Models\MealEntry;
use App\Models\NutritionTarget;
use App\Models\Recipe;
use App\Models\UserFavoriteRecipe;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NutritionController extends Controller
{
    public function recipes(): JsonResponse
    {
        return ApiResponse::success(RecipeResource::collection(Recipe::query()->orderBy('name')->get()));
    }

    public function foods(Request $request): JsonResponse
    {
        $foods = Food::query()->when($request->filled('search'), fn ($q) => $q->where('name', 'like', '%'.$request->string('search').'%'))->when($request->filled('category'), fn ($q) => $q->where('category', $request->string('category')))->when($request->boolean('tunisian'), fn ($q) => $q->where('is_tunisian', true))->orderBy('name')->get();
        return ApiResponse::success(FoodResource::collection($foods));
    }

    public function summary(Request $request): JsonResponse
    {
        $date = $request->input('date', now()->toDateString());
        $meals = $request->user()->mealEntries()->whereDate('date', $date)->get();
        $target = $request->user()->nutritionTarget;
        return ApiResponse::success(['date' => $date, 'meals' => MealEntryResource::collection($meals), 'totals' => ['calories' => (int) $meals->sum('calories'), 'protein' => (float) $meals->sum('protein'), 'carbs' => (float) $meals->sum('carbs'), 'fat' => (float) $meals->sum('fat')], 'targets' => $target ? new NutritionTargetResource($target) : null]);
    }

    /**
     * Calories / protein per day for the last 7 days (for the weekly chart).
     */
    public function week(Request $request): JsonResponse
    {
        $end = now()->startOfDay();
        $start = $end->copy()->subDays(6);
        $meals = $request->user()->mealEntries()
            ->whereDate('date', '>=', $start->toDateString())
            ->whereDate('date', '<=', $end->toDateString())
            ->get()
            ->groupBy(fn ($meal) => $meal->date->format('Y-m-d'));
        $target = $request->user()->nutritionTarget;

        $days = [];
        for ($day = $start->copy(); $day->lte($end); $day->addDay()) {
            $key = $day->toDateString();
            $dayMeals = $meals->get($key, collect());
            $days[] = [
                'date' => $key,
                'calories' => (int) $dayMeals->sum('calories'),
                'protein' => round((float) $dayMeals->sum('protein'), 1),
                'carbs' => round((float) $dayMeals->sum('carbs'), 1),
                'fat' => round((float) $dayMeals->sum('fat'), 1),
                'meals' => $dayMeals->count(),
            ];
        }

        $logged = collect($days)->where('meals', '>', 0);

        return ApiResponse::success([
            'days' => $days,
            'averageCalories' => (int) round($logged->avg('calories') ?? 0),
            'averageProtein' => round((float) ($logged->avg('protein') ?? 0), 1),
            'targetCalories' => $target ? (int) $target->calories : null,
            'targetProtein' => $target ? (float) $target->protein : null,
        ]);
    }

    public function meals(Request $request): JsonResponse
    {
        $meals = $request->user()->mealEntries()->when($request->filled('date'), fn ($q) => $q->whereDate('date', $request->date))->orderBy('date')->orderBy('time')->get();
        return ApiResponse::success(MealEntryResource::collection($meals));
    }

    public function storeMeal(StoreMealRequest $request): JsonResponse
    {
        $meal = $request->user()->mealEntries()->create(['food_id' => $request->input('foodId'), 'recipe_slug' => $request->input('recipeId'), 'date' => $request->date, 'type' => $request->type, 'name' => $request->name, 'time' => $request->time, 'calories' => $request->calories, 'protein' => $request->protein, 'carbs' => $request->carbs, 'fat' => $request->fat]);
        return ApiResponse::success(new MealEntryResource($meal), 'Meal created successfully.', [], 201);
    }

    public function updateMeal(Request $request, int $meal): JsonResponse
    {
        $entry = $request->user()->mealEntries()->find($meal);
        if (! $entry) return ApiResponse::error('Unauthorized.', [], 403);
        $entry->update($request->only(['date', 'type', 'name', 'time', 'calories', 'protein', 'carbs', 'fat', 'food_id', 'recipe_slug']));
        return ApiResponse::success(new MealEntryResource($entry->fresh()), 'Meal updated successfully.');
    }

    public function deleteMeal(Request $request, int $meal): JsonResponse
    {
        $entry = $request->user()->mealEntries()->find($meal);
        if (! $entry) return ApiResponse::error('Unauthorized.', [], 403);
        $entry->delete();
        return ApiResponse::success(null, 'Meal deleted successfully.');
    }

    public function targets(Request $request): JsonResponse
    {
        $target = $request->user()->nutritionTarget()->first();

        return ApiResponse::success($target ? new NutritionTargetResource($target) : null);
    }

    public function updateTargets(UpdateNutritionTargetRequest $request): JsonResponse
    {
        $target = $request->user()->nutritionTarget()->updateOrCreate([], $request->only(['calories', 'protein', 'carbs', 'fat']));
        return ApiResponse::success(new NutritionTargetResource($target), 'Nutrition targets updated successfully.');
    }

    public function favorites(Request $request): JsonResponse
    {
        return ApiResponse::success(RecipeResource::collection($request->user()->favoriteRecipes()->with('recipe')->get()->pluck('recipe')));
    }

    public function favorite(Request $request, string $recipe): JsonResponse
    {
        Recipe::where('slug', $recipe)->firstOrFail();
        $favorite = $request->user()->favoriteRecipes()->firstOrCreate(['recipe_slug' => $recipe]);
        return ApiResponse::success(['id' => $favorite->id, 'recipeId' => $recipe], 'Recipe favorited successfully.', [], 201);
    }

    public function unfavorite(Request $request, string $recipe): JsonResponse
    {
        $request->user()->favoriteRecipes()->where('recipe_slug', $recipe)->delete();
        return ApiResponse::success(null, 'Recipe unfavorited successfully.');
    }
}
