<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\FoodResource;
use App\Http\Resources\RecipeResource;
use App\Models\Food;
use App\Models\Recipe;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

/**
 * Admin management of the food database and recipes.
 */
class AdminNutritionController extends Controller
{
    public const FOOD_CATEGORIES = ['protein', 'starch', 'legume', 'dairy', 'fruit', 'vegetable', 'nuts', 'fat', 'snack', 'drink', 'tunisian'];

    public const MEAL_TYPES = ['breakfast', 'lunch', 'snack', 'dinner'];

    public const GOALS = ['lose_weight', 'gain_muscle', 'clean_bulk', 'maintain', 'endurance'];

    // ─── Foods ───────────────────────────────────────────────────────

    protected function foodRules(bool $creating): array
    {
        $req = $creating ? 'required' : 'sometimes';

        return [
            'name' => [$req, 'string', 'max:255'],
            'category' => [$req, Rule::in(self::FOOD_CATEGORIES)],
            'serving' => [$req, 'string', 'max:100'],
            'calories' => [$req, 'integer', 'min:0', 'max:5000'],
            'protein' => [$req, 'numeric', 'min:0', 'max:500'],
            'carbs' => [$req, 'numeric', 'min:0', 'max:500'],
            'fat' => [$req, 'numeric', 'min:0', 'max:500'],
            'isTunisian' => ['sometimes', 'boolean'],
        ];
    }

    protected function foodAttributes(array $data): array
    {
        $map = ['name' => 'name', 'category' => 'category', 'serving' => 'serving', 'calories' => 'calories', 'protein' => 'protein', 'carbs' => 'carbs', 'fat' => 'fat', 'isTunisian' => 'is_tunisian'];
        $attributes = [];
        foreach ($map as $input => $column) {
            if (array_key_exists($input, $data)) {
                $attributes[$column] = $data[$input];
            }
        }

        return $attributes;
    }

    public function storeFood(Request $request): JsonResponse
    {
        $data = $request->validate($this->foodRules(true));
        $food = Food::create(['slug' => $this->uniqueSlug(Food::class, $data['name'])] + $this->foodAttributes($data));

        return ApiResponse::success(new FoodResource($food), 'Food created successfully.', [], 201);
    }

    public function updateFood(Request $request, string $slug): JsonResponse
    {
        $food = Food::find($slug);
        if (! $food) {
            return ApiResponse::error('Food not found.', [], 404);
        }

        $food->update($this->foodAttributes($request->validate($this->foodRules(false))));

        return ApiResponse::success(new FoodResource($food->fresh()), 'Food updated successfully.');
    }

    public function destroyFood(string $slug): JsonResponse
    {
        $food = Food::find($slug);
        if (! $food) {
            return ApiResponse::error('Food not found.', [], 404);
        }

        // Meals already logged keep their name & macros (food_id becomes null).
        $food->delete();

        return ApiResponse::success(null, 'Food deleted successfully.');
    }

    // ─── Recipes ─────────────────────────────────────────────────────

    protected function recipeRules(bool $creating): array
    {
        $req = $creating ? 'required' : 'sometimes';

        return [
            'name' => [$req, 'string', 'max:255'],
            'subtitle' => ['sometimes', 'nullable', 'string', 'max:255'],
            'calories' => [$req, 'integer', 'min:0', 'max:5000'],
            'protein' => [$req, 'numeric', 'min:0', 'max:500'],
            'carbs' => ['sometimes', 'numeric', 'min:0', 'max:500'],
            'fat' => ['sometimes', 'numeric', 'min:0', 'max:500'],
            'duration' => [$req, 'integer', 'min:1', 'max:600'],
            'mealType' => ['sometimes', 'nullable', Rule::in(self::MEAL_TYPES)],
            'goalTags' => ['sometimes', 'array'],
            'goalTags.*' => [Rule::in(self::GOALS)],
            'ingredients' => ['sometimes', 'array'],
            'ingredients.*' => ['string', 'max:255'],
            'steps' => ['sometimes', 'array'],
            'steps.*' => ['string', 'max:1000'],
            'icon' => ['sometimes', 'nullable', Rule::in(['rice_bowl', 'breakfast', 'blender', 'dinner', 'lunch', 'snack'])],
            'accent' => ['sometimes', 'nullable', Rule::in(['mint', 'amber', 'violet', 'coral', 'cyan', 'volt'])],
            'isTunisian' => ['sometimes', 'boolean'],
        ];
    }

    protected function recipeAttributes(array $data): array
    {
        $map = [
            'name' => 'name', 'subtitle' => 'subtitle', 'calories' => 'calories', 'protein' => 'protein',
            'carbs' => 'carbs', 'fat' => 'fat', 'duration' => 'duration', 'mealType' => 'meal_type',
            'goalTags' => 'goal_tags', 'ingredients' => 'ingredients', 'steps' => 'steps',
            'icon' => 'icon_key', 'accent' => 'accent_key', 'isTunisian' => 'is_tunisian',
        ];
        $attributes = [];
        foreach ($map as $input => $column) {
            if (array_key_exists($input, $data)) {
                $attributes[$column] = $data[$input];
            }
        }
        if (array_key_exists('subtitle', $attributes) && $attributes['subtitle'] === null) {
            $attributes['subtitle'] = '';
        }

        return $attributes;
    }

    public function storeRecipe(Request $request): JsonResponse
    {
        $data = $request->validate($this->recipeRules(true));
        $recipe = Recipe::create(array_merge([
            'slug' => $this->uniqueSlug(Recipe::class, $data['name']),
            'subtitle' => '',
            'carbs' => 0,
            'fat' => 0,
            'goal_tags' => self::GOALS,
            'icon_key' => 'dinner',
            'accent_key' => 'mint',
        ], $this->recipeAttributes($data)));

        return ApiResponse::success(new RecipeResource($recipe), 'Recipe created successfully.', [], 201);
    }

    public function updateRecipe(Request $request, string $slug): JsonResponse
    {
        $recipe = Recipe::find($slug);
        if (! $recipe) {
            return ApiResponse::error('Recipe not found.', [], 404);
        }

        $recipe->update($this->recipeAttributes($request->validate($this->recipeRules(false))));

        return ApiResponse::success(new RecipeResource($recipe->fresh()), 'Recipe updated successfully.');
    }

    public function destroyRecipe(string $slug): JsonResponse
    {
        $recipe = Recipe::find($slug);
        if (! $recipe) {
            return ApiResponse::error('Recipe not found.', [], 404);
        }

        $recipe->delete();

        return ApiResponse::success(null, 'Recipe deleted successfully.');
    }

    protected function uniqueSlug(string $model, string $name): string
    {
        $base = Str::slug($name) ?: 'item';
        $slug = $base;
        $i = 2;
        while ($model::query()->where('slug', $slug)->exists()) {
            $slug = $base.'-'.$i++;
        }

        return $slug;
    }
}
