<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\ExerciseIndexRequest;
use App\Http\Resources\ExerciseResource;
use App\Models\Exercise;
use App\Support\ApiResponse;
use App\Support\ExerciseStats;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ExerciseController extends Controller
{
    /**
     * Full library, no pagination (the app needs every exercise used by sessions).
     * Filters: category, muscleGroup, level, atHome=1, search.
     */
    public function index(ExerciseIndexRequest $request): JsonResponse
    {
        $query = Exercise::query();

        if ($request->filled('category')) {
            $query->where('category', $request->input('category'));
        }

        if ($request->filled('muscleGroup')) {
            $query->where('muscle_group', $request->input('muscleGroup'));
        }

        if ($request->filled('level')) {
            $query->where('level', $request->input('level'));
        }

        if ($request->boolean('atHome')) {
            $query->where('at_home', true);
        }

        if ($request->filled('search')) {
            $search = (string) $request->input('search');
            $query->where(function ($builder) use ($search) {
                $builder->where('name', 'like', "%{$search}%")
                    ->orWhere('slug', 'like', "%{$search}%")
                    ->orWhere('muscles', 'like', "%{$search}%");
            });
            // Exact slug first, then names starting with the search.
            $query->orderByRaw('CASE WHEN slug = ? THEN 0 WHEN name LIKE ? THEN 1 ELSE 2 END', [$search, $search.'%']);
        }

        $exercises = $query->orderBy('name')->get();
        $perfs = ExerciseStats::lastPerformances($request->user());

        $exercises->each(fn (Exercise $exercise) => $exercise->setAttribute('user_last_perf', $perfs[$exercise->slug] ?? null));

        return ApiResponse::success(
            ExerciseResource::collection($exercises),
            'Success',
            ['total' => $exercises->count()]
        );
    }

    /**
     * One exercise + the user's real history on it.
     */
    public function show(Request $request, string $slug): JsonResponse
    {
        $exercise = Exercise::find($slug);
        if (! $exercise) {
            return ApiResponse::error('Exercise not found.', [], 404);
        }

        $history = ExerciseStats::history($request->user(), $slug);
        $exercise->setAttribute('user_last_perf', $history['sessions'][0]['summary'] ?? null);

        return ApiResponse::success([
            'exercise' => new ExerciseResource($exercise),
            'history' => $history,
        ]);
    }
}
