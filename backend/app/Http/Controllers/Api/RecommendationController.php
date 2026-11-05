<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\RecommendedProgramResource;
use App\Support\ApiResponse;
use App\Support\ProgramRecommender;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RecommendationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $recommendations = ProgramRecommender::topFor($request->user(), 3);

        return ApiResponse::success(
            RecommendedProgramResource::collection($recommendations)
        );
    }
}
