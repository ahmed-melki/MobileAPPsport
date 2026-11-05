<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\AiAdvisor;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * AI recommendations: training (goal + level) and nutrition (goal + today's meals).
 */
class AiRecommendationController extends Controller
{
    public function training(Request $request): JsonResponse
    {
        return ApiResponse::success(AiAdvisor::training($request->user()), 'Training recommendation generated.');
    }

    public function nutrition(Request $request): JsonResponse
    {
        $validated = $request->validate(['hour' => ['nullable', 'integer', 'min:0', 'max:23']]);

        return ApiResponse::success(
            AiAdvisor::nutrition($request->user(), isset($validated['hour']) ? (int) $validated['hour'] : null),
            'Nutrition recommendation generated.'
        );
    }
}
