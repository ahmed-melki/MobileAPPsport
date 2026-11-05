<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\ApiResponse;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $logs = $user->sessionLogs()
            ->reorder()
            ->whereRaw('COALESCE(completed_at, date) >= ?', [Carbon::now()->subDays(28)])
            ->orderByRaw('COALESCE(completed_at, date) asc')
            ->get();

        $weeklySessions = $logs->filter(fn ($log) => ($log->completed_at ?? $log->date)->greaterThanOrEqualTo(Carbon::now()->subDays(7)))->count();

        $streakDays = 0;
        $cursor = Carbon::today();
        $uniqueDates = $logs->map(fn ($log) => ($log->completed_at ?? $log->date)->toDateString())->unique()->values();

        while ($uniqueDates->contains($cursor->toDateString())) {
            $streakDays++;
            $cursor->subDay();
        }

        $activeWeeks = $logs->map(fn ($log) => ($log->completed_at ?? $log->date)->format('o-W'))->unique()->count();
        $readiness = round(min($weeklySessions / 5, 1) * 100 * 0.5 + min($activeWeeks / 4, 1) * 100 * 0.3 + min($streakDays / 7, 1) * 100 * 0.2);

        return ApiResponse::success([
            'firstName' => $user->first_name,
            'readiness' => max(0, min(100, (int) $readiness)),
            'streakDays' => $streakDays,
            'weeklySessions' => $weeklySessions,
        ], 'Dashboard loaded successfully.');
    }
}
