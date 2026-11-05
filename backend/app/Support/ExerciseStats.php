<?php

namespace App\Support;

use App\Models\SessionLogSet;
use App\Models\User;
use Illuminate\Support\Collection;

/**
 * Real per-user performance, computed from the sets the user logged
 * (session_logs + session_log_sets). Replaces the static "last_perf" text.
 */
class ExerciseStats
{
    /**
     * All logged sets of a user, newest session first.
     */
    protected static function userSets(User $user, ?string $exerciseSlug = null): Collection
    {
        return SessionLogSet::query()
            ->join('session_logs', 'session_logs.id', '=', 'session_log_sets.session_log_id')
            ->where('session_logs.user_id', $user->id)
            ->when($exerciseSlug, fn ($q) => $q->where('session_log_sets.exercise_slug', $exerciseSlug))
            ->orderByRaw('COALESCE(session_logs.completed_at, session_logs.date) DESC')
            ->orderByDesc('session_logs.id')
            ->orderBy('session_log_sets.set_number')
            ->get([
                'session_log_sets.*',
                'session_logs.completed_at as log_completed_at',
                'session_logs.date as log_date',
            ]);
    }

    /**
     * Map exercise slug => short text of the last performance, e.g. "4 × 6 @ 92,5 kg".
     *
     * @return array<string, string>
     */
    public static function lastPerformances(User $user): array
    {
        $result = [];
        $grouped = self::userSets($user)->groupBy('exercise_slug');

        foreach ($grouped as $slug => $sets) {
            $lastLogId = $sets->first()->session_log_id;
            $result[$slug] = self::format($sets->where('session_log_id', $lastLogId));
        }

        return $result;
    }

    /**
     * Last session (sets) for one exercise, used by the AI coach for progressive overload.
     */
    public static function lastSession(User $user, string $slug): ?Collection
    {
        $sets = self::userSets($user, $slug);
        if ($sets->isEmpty()) {
            return null;
        }

        return $sets->where('session_log_id', $sets->first()->session_log_id)->values();
    }

    /**
     * History of one exercise: one point per session (most recent first), plus personal best.
     */
    public static function history(User $user, string $slug, int $limit = 10): array
    {
        $sets = self::userSets($user, $slug);

        $sessions = $sets->groupBy('session_log_id')->take($limit)->map(function (Collection $logSets) {
            $first = $logSets->first();
            $date = $first->log_completed_at ?? $first->log_date;

            return [
                'date' => $date ? substr((string) $date, 0, 10) : null,
                'sets' => $logSets->count(),
                'totalReps' => (int) $logSets->sum('reps'),
                'bestLoadKg' => round((float) $logSets->max('load_kg'), 2),
                'volumeKg' => round((float) $logSets->sum(fn ($s) => $s->kind === 'load' ? $s->reps * (float) $s->load_kg : 0), 1),
                'summary' => self::format($logSets),
            ];
        })->values();

        $best = $sets->sortByDesc(fn ($s) => [(float) $s->load_kg, $s->reps])->first();

        return [
            'sessions' => $sessions,
            'personalBest' => $best ? [
                'loadKg' => round((float) $best->load_kg, 2),
                'reps' => (int) $best->reps,
                'kind' => $best->kind,
                'unitNote' => $best->unit_note,
            ] : null,
            'timesPerformed' => $sets->pluck('session_log_id')->unique()->count(),
        ];
    }

    public static function format(Collection $sets): string
    {
        if ($sets->isEmpty()) {
            return '';
        }

        $count = $sets->count();
        $reps = (int) round($sets->avg('reps'));
        $first = $sets->first();
        $load = (float) $sets->max('load_kg');

        return match ($first->kind) {
            'distance' => sprintf('%d × %d %s', $count, $reps, $first->unit_note ?: 'm'),
            'bodyweight' => sprintf('%d × %d', $count, $reps),
            default => sprintf('%d × %d @ %s kg', $count, $reps, self::kg($load)),
        };
    }

    public static function kg(float $value): string
    {
        $formatted = fmod($value, 1.0) === 0.0 ? number_format($value, 0) : number_format($value, 1, ',', '');

        return $formatted;
    }
}
