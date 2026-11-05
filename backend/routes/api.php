<?php

use App\Http\Controllers\Api\Admin\AdminNutritionController;
use App\Http\Controllers\Api\Admin\AdminOrderController;
use App\Http\Controllers\Api\Admin\AdminProductController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BodyMeasurementController;
use App\Http\Controllers\Api\CoachAiController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\CoachController;
use App\Http\Controllers\Api\ExerciseController;
use App\Http\Controllers\Api\GoalController;
use App\Http\Controllers\Api\OnboardingController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\RecommendationController;
use App\Http\Controllers\Api\ShopController;
use App\Http\Controllers\Api\SessionLogController;
use App\Http\Controllers\Api\TrainingProgressController;
use App\Http\Controllers\Api\TrainingProgramController;
use App\Http\Controllers\Api\UserProgramController;
use App\Http\Controllers\Api\WorkoutSessionController;
use App\Http\Controllers\Api\NutritionController;
use App\Http\Middleware\EnsureEmailIsVerified;
use App\Http\Middleware\EnsureUserIsAdmin;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::prefix('auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/logout', [AuthController::class, 'logout'])->middleware('auth:sanctum');

    Route::middleware('throttle:auth-codes')->group(function () {
        Route::post('/verify-email', [AuthController::class, 'verifyEmail']);
        Route::post('/resend-code', [AuthController::class, 'resendCode']);
        Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
        Route::post('/reset-password', [AuthController::class, 'resetPassword']);
    });
});

Route::get('/shop/governorates', [ShopController::class, 'governorates']);

Route::middleware(['auth:sanctum', EnsureEmailIsVerified::class])->group(function () {
    Route::get('/exercises', [ExerciseController::class, 'index']);
    Route::get('/exercises/{slug}', [ExerciseController::class, 'show']);

    Route::prefix('training')->group(function () {
        Route::get('/programs', [TrainingProgramController::class, 'index']);
        Route::get('/programs/{slug}', [TrainingProgramController::class, 'show']);
        Route::get('/sessions/{slug}', [WorkoutSessionController::class, 'show']);
    });

    Route::get('/me', [ProfileController::class, 'show']);
    Route::put('/me', [ProfileController::class, 'update']);
    Route::post('/me/change-password', [AuthController::class, 'changePassword']);
    Route::post('/me/onboarding', [OnboardingController::class, 'store']);
    Route::get('/me/recommendations', [RecommendationController::class, 'index']);

    Route::get('/me/goals', [GoalController::class, 'index']);
    Route::post('/me/goals', [GoalController::class, 'store']);
    Route::patch('/me/goals/{goal}', [GoalController::class, 'update']);
    Route::delete('/me/goals/{goal}', [GoalController::class, 'destroy']);

    Route::get('/me/measurements', [BodyMeasurementController::class, 'index']);
    Route::post('/me/measurements', [BodyMeasurementController::class, 'store']);

    Route::post('/me/session-logs', [SessionLogController::class, 'store']);
    Route::get('/me/session-logs', [SessionLogController::class, 'index']);
    Route::get('/me/training-progress', [TrainingProgressController::class, 'index']);
    Route::get('/me/programs', [UserProgramController::class, 'index']);
    Route::post('/me/programs/{slug}/start', [UserProgramController::class, 'start']);
    Route::post('/me/programs/{slug}/pause', [UserProgramController::class, 'pause']);

    Route::get('/me/dashboard', [DashboardController::class, 'index']);

    Route::prefix('nutrition')->group(function () {
        Route::get('/recipes', [NutritionController::class, 'recipes']);
        Route::get('/foods', [NutritionController::class, 'foods']);
    });

    Route::get('/me/nutrition/summary', [NutritionController::class, 'summary']);
    Route::get('/me/nutrition/week', [NutritionController::class, 'week']);
    Route::get('/me/meals', [NutritionController::class, 'meals']);
    Route::post('/me/meals', [NutritionController::class, 'storeMeal']);
    Route::put('/me/meals/{meal}', [NutritionController::class, 'updateMeal']);
    Route::delete('/me/meals/{meal}', [NutritionController::class, 'deleteMeal']);
    Route::get('/me/nutrition-targets', [NutritionController::class, 'targets']);
    Route::put('/me/nutrition-targets', [NutritionController::class, 'updateTargets']);
    Route::get('/me/favorites/recipes', [NutritionController::class, 'favorites']);
    Route::post('/me/favorites/recipes/{recipe}', [NutritionController::class, 'favorite']);
    Route::delete('/me/favorites/recipes/{recipe}', [NutritionController::class, 'unfavorite']);

    // Coach Apex (AI)
    Route::get('/me/coach/today', [CoachAiController::class, 'today']);
    Route::get('/me/ai/training', [\App\Http\Controllers\Api\AiRecommendationController::class, 'training'])->middleware('throttle:30,1');
    Route::get('/me/ai/nutrition', [\App\Http\Controllers\Api\AiRecommendationController::class, 'nutrition'])->middleware('throttle:30,1');
    Route::post('/me/coach/chat', [CoachAiController::class, 'chat'])->middleware('throttle:20,1');

    Route::get('/coaches', [CoachController::class, 'index']);
    Route::get('/coaches/{slug}', [CoachController::class, 'show']);
    Route::get('/coaches/{slug}/availability', [CoachController::class, 'availability']);
    Route::get('/me/bookings', [CoachController::class, 'bookings']);
    Route::post('/me/bookings', [CoachController::class, 'storeBooking']);
    Route::patch('/me/bookings/{booking}', [CoachController::class, 'cancel']);
    Route::post('/coach/bookings/{booking}/confirm', [CoachController::class, 'confirm']);
    Route::post('/coach/bookings/{booking}/decline', [CoachController::class, 'decline']);
    Route::get('/coach/athletes', [CoachController::class, 'athletes']);

    Route::get('/products', [ShopController::class, 'products']);
    Route::get('/products/{slug}', [ShopController::class, 'product']);
    Route::post('/products/{slug}/reviews', [ShopController::class, 'review']);
    Route::get('/me/favorites/products', [ShopController::class, 'favorites']);
    Route::post('/me/favorites/products/{slug}', [ShopController::class, 'favorite']);
    Route::delete('/me/favorites/products/{slug}', [ShopController::class, 'unfavorite']);
    Route::get('/me/cart', [ShopController::class, 'cart']);
    Route::post('/me/cart/items', [ShopController::class, 'addCartItem']);
    Route::patch('/me/cart/items/{slug}', [ShopController::class, 'updateCartItem']);
    Route::delete('/me/cart/items/{slug}', [ShopController::class, 'deleteCartItem']);
    Route::post('/me/orders', [ShopController::class, 'createOrder']);
    Route::get('/me/orders', [ShopController::class, 'orders']);
    Route::get('/me/orders/{orderNumber}', [ShopController::class, 'showOrder']);
    Route::post('/me/orders/{orderNumber}/cancel', [ShopController::class, 'cancelOrder']);
});

Route::prefix('admin')->middleware(['auth:sanctum', EnsureUserIsAdmin::class])->group(function () {
    Route::get('/orders', [AdminOrderController::class, 'index']);
    Route::get('/orders/{orderNumber}', [AdminOrderController::class, 'show']);
    Route::patch('/orders/{orderNumber}/status', [AdminOrderController::class, 'updateStatus']);

    Route::get('/products', [AdminProductController::class, 'index']);
    Route::post('/products', [AdminProductController::class, 'store']);
    Route::put('/products/{slug}', [AdminProductController::class, 'update']);
    Route::patch('/products/{slug}/stock', [AdminProductController::class, 'updateStock']);
    Route::patch('/products/{slug}/deactivate', [AdminProductController::class, 'deactivate']);
    Route::patch('/products/{slug}/restore', [AdminProductController::class, 'restore']);

    Route::post('/foods', [AdminNutritionController::class, 'storeFood']);
    Route::put('/foods/{slug}', [AdminNutritionController::class, 'updateFood']);
    Route::delete('/foods/{slug}', [AdminNutritionController::class, 'destroyFood']);
    Route::post('/recipes', [AdminNutritionController::class, 'storeRecipe']);
    Route::put('/recipes/{slug}', [AdminNutritionController::class, 'updateRecipe']);
    Route::delete('/recipes/{slug}', [AdminNutritionController::class, 'destroyRecipe']);
});

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');
