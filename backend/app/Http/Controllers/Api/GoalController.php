<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreGoalRequest;
use App\Http\Requests\UpdateGoalRequest;
use App\Http\Resources\GoalResource;
use App\Models\Goal;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class GoalController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $goals = $request->user()->goals()->get();

        return ApiResponse::success(GoalResource::collection($goals));
    }

    public function store(StoreGoalRequest $request): JsonResponse
    {
        $user = $request->user();

        $goal = DB::transaction(function () use ($user, $request) {
            if ($request->boolean('primary', false)) {
                $user->goals()->where('is_primary', true)->update(['is_primary' => false]);
            }

            return $user->goals()->create([
                'kind' => $request->input('kind'),
                'detail' => $request->input('detail'),
                'target' => $request->input('target'),
                'deadline' => $request->input('deadline'),
                'progress' => $request->input('progress', 0),
                'is_active' => $request->boolean('active', true),
                'is_primary' => $request->boolean('primary', false),
            ]);
        });

        return ApiResponse::success(new GoalResource($goal), 'Goal created successfully.', [], 201);
    }

    public function update(UpdateGoalRequest $request, Goal $goal): JsonResponse
    {
        if ($goal->user_id !== $request->user()->id) {
            return ApiResponse::error('Unauthorized.', [], 403);
        }

        $goal = DB::transaction(function () use ($request, $goal) {
            if ($request->has('primary') && $request->boolean('primary')) {
                $goal->user->goals()->where('is_primary', true)->whereKeyNot($goal->id)->update(['is_primary' => false]);
            }

            $goal->fill([
                'kind' => $request->input('kind', $goal->kind),
                'detail' => $request->input('detail', $goal->detail),
                'target' => $request->input('target', $goal->target),
                'deadline' => $request->input('deadline', $goal->deadline),
                'progress' => $request->input('progress', $goal->progress),
                'is_active' => $request->input('active', $goal->is_active),
                'is_primary' => $request->input('primary', $goal->is_primary),
            ]);

            $goal->save();

            return $goal->fresh();
        });

        return ApiResponse::success(new GoalResource($goal), 'Goal updated successfully.');
    }

    public function destroy(Request $request, Goal $goal): JsonResponse
    {
        if ($goal->user_id !== $request->user()->id) {
            return ApiResponse::error('Unauthorized.', [], 403);
        }

        $goal->delete();

        return ApiResponse::success(null, 'Goal deleted successfully.');
    }
}
