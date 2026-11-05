<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreOnboardingRequest;
use App\Http\Resources\RecommendedProgramResource;
use App\Http\Resources\UserResource;
use App\Support\ApiResponse;
use App\Support\OnboardingService;
use App\Support\ProgramRecommender;
use Illuminate\Http\JsonResponse;

class OnboardingController extends Controller
{
    public function store(StoreOnboardingRequest $request, OnboardingService $onboarding): JsonResponse
    {
        $user = $onboarding->complete($request->user(), $request->validated());
        $recommendations = ProgramRecommender::topFor($user, 3);

        return ApiResponse::success([
            'profile' => (new UserResource($user))->resolve($request),
            'recommendations' => RecommendedProgramResource::collection($recommendations)->resolve($request),
        ], 'Onboarding completed successfully.');
    }
}
