<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserProgramResource;
use App\Models\TrainingProgram;
use App\Models\UserProgram;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class UserProgramController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $programs = $request->user()->userPrograms()->with('program')->get();

        if ($programs->isEmpty()) {
            $defaultProgram = TrainingProgram::first();

            if ($defaultProgram) {
                $programs = collect([
                    $request->user()->userPrograms()->firstOrCreate(
                        ['program_slug' => $defaultProgram->slug],
                        ['status' => 'active', 'started_at' => now()]
                    )->load('program'),
                ]);
            }
        }

        return ApiResponse::success(UserProgramResource::collection($programs));
    }

    public function start(Request $request, string $slug): JsonResponse
    {
        $program = TrainingProgram::where('slug', $slug)->firstOrFail();

        $userProgram = UserProgram::firstOrCreate(
            ['user_id' => $request->user()->id, 'program_slug' => $program->slug],
            ['status' => 'active', 'started_at' => now()]
        );

        $userProgram->status = 'active';
        $userProgram->started_at = $userProgram->started_at ?? now();
        $userProgram->paused_at = null;
        $userProgram->save();

        $userProgram->load('program');

        return ApiResponse::success(new UserProgramResource($userProgram));
    }

    public function pause(Request $request, string $slug): JsonResponse
    {
        $program = TrainingProgram::where('slug', $slug)->firstOrFail();

        $userProgram = UserProgram::firstOrCreate(
            ['user_id' => $request->user()->id, 'program_slug' => $program->slug],
            ['status' => 'paused', 'paused_at' => now()]
        );

        $userProgram->status = 'paused';
        $userProgram->paused_at = now();
        $userProgram->save();

        $userProgram->load('program');

        return ApiResponse::success(new UserProgramResource($userProgram));
    }
}
