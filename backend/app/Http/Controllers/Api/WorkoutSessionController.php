<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\WorkoutSessionResource;
use App\Models\WorkoutSession;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

class WorkoutSessionController extends Controller
{
    public function show(string $slug): JsonResponse
    {
        $session = WorkoutSession::with('exercises.exercise')->where('slug', $slug)->firstOrFail();

        return ApiResponse::success(new WorkoutSessionResource($session));
    }
}
