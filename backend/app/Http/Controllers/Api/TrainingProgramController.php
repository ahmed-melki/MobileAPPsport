<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\TrainingProgramResource;
use App\Models\TrainingProgram;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

class TrainingProgramController extends Controller
{
    public function index(): JsonResponse
    {
        $programs = TrainingProgram::with('sessions.exercises')->get();

        return ApiResponse::success(TrainingProgramResource::collection($programs));
    }

    public function show(string $slug): JsonResponse
    {
        $program = TrainingProgram::with('sessions.exercises')->where('slug', $slug)->firstOrFail();

        return ApiResponse::success(new TrainingProgramResource($program));
    }
}
