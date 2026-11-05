<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

class TrainingProgressController extends Controller
{
    public function index(): JsonResponse
    {
        $logs = auth()->user()->sessionLogs()->with('sets.exercise')->reorder()->orderByRaw('COALESCE(completed_at, date) asc')->get();
        $grouped = [];

        foreach ($logs as $log) {
            $maxLoadsForLog = [];

            foreach ($log->sets as $set) {
                if ($set->kind !== 'load' || ! $set->exercise) {
                    continue;
                }

                $exerciseSlug = $set->exercise_slug;

                $maxLoadsForLog[$exerciseSlug] = max(
                    $maxLoadsForLog[$exerciseSlug] ?? 0,
                    (float) ($set->load_kg ?? 0),
                );

                if (! isset($grouped[$exerciseSlug])) {
                    $grouped[$exerciseSlug] = [
                        'name' => $set->exercise->name,
                        'unit' => 'kg',
                        'points' => [],
                    ];
                }

            }

            foreach ($maxLoadsForLog as $exerciseSlug => $maxLoad) {
                $grouped[$exerciseSlug]['points'][] = $maxLoad;
            }
        }

        $result = [];
        foreach ($grouped as $entry) {
            $result[] = [
                'name' => $entry['name'],
                'unit' => $entry['unit'],
                'points' => $entry['points'],
            ];
        }

        return ApiResponse::success($result);
    }
}
