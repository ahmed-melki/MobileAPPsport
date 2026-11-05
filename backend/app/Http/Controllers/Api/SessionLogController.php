<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreSessionLogRequest;
use App\Http\Resources\SessionLogResource;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class SessionLogController extends Controller
{
    public function index(): JsonResponse
    {
        $logs = auth()->user()->sessionLogs()->with('sets')->orderByDesc('date')->get();

        return ApiResponse::success(SessionLogResource::collection($logs));
    }

    public function store(StoreSessionLogRequest $request): JsonResponse
    {
        $log = DB::transaction(function () use ($request) {
            $sessionId = $request->input('sessionId', $request->input('sessionSlug'));
            $programId = $request->input('programId', $request->input('programSlug'));
            $completedAt = $request->input('completedAt', $request->input('date'));

            $sessionLog = auth()->user()->sessionLogs()->create([
                'session_slug' => $sessionId,
                'program_slug' => $programId,
                'session_title' => $request->input('sessionTitle') ?? $sessionId,
                'program_title' => $request->input('programTitle') ?? $programId,
                'completed_at' => $completedAt,
                'date' => $completedAt ? \Carbon\Carbon::parse($completedAt)->toDateString() : null,
                'duration_min' => $request->input('durationMin'),
                'highlight' => $request->input('highlight'),
            ]);

            foreach ($request->input('sets', []) as $setPayload) {
                $sessionLog->sets()->create([
                    'exercise_slug' => $setPayload['exerciseId'] ?? $setPayload['exerciseSlug'] ?? null,
                    'set_number' => $setPayload['setNumber'] ?? 1,
                    'reps' => $setPayload['reps'],
                    'load_kg' => $setPayload['loadKg'] ?? $setPayload['load'] ?? 0,
                    'kind' => $setPayload['kind'],
                    'unit_note' => $setPayload['unitNote'] ?? null,
                ]);
            }

            return $sessionLog->load('sets');
        });

        return ApiResponse::success(new SessionLogResource($log), 'Session logged successfully.', [], 201);
    }
}
