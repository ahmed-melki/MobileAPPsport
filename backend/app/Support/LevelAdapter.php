<?php

namespace App\Support;

use App\Models\Exercise;
use App\Models\User;

/**
 * Makes every prescribed exercise match the user's level.
 *
 * - An exercise harder than the user's level is replaced by an easier variant
 *   (ex. débutant : squat barre → goblet squat, tractions → tirage vertical).
 * - Volume: débutant max 3 séries + 15 s de repos en plus ; avancé : volume du programme.
 * - Progression: débutant +2,5 kg, intermédiaire +5 kg (gros mouvements) / +2,5 kg,
 *   avancé +2,5 kg / +1,25 kg (on progresse plus lentement quand on est fort).
 */
class LevelAdapter
{
    /** Harder → easier variant for a beginner. */
    public const BEGINNER_SUBS = [
        'squat' => 'goblet-squat',
        'front-squat' => 'goblet-squat',
        'thruster' => 'goblet-squat',
        'bench' => 'db-bench',
        'dips' => 'bench-dips',
        'deadlift' => 'glute-bridge',
        'romanian-deadlift' => 'glute-bridge',
        'good-morning' => 'glute-bridge',
        'kb-swing' => 'glute-bridge',
        'pclean' => 'goblet-squat',
        'pullup' => 'lat-pulldown',
        'barbell-row' => 'db-row',
        'ohp' => 'db-shoulder-press',
        'push-press' => 'db-shoulder-press',
        'db-snatch' => 'db-shoulder-press',
        'pike-pushup' => 'incline-pushup',
        'wallball' => 'bodyweight-squat',
        'sled-push' => 'step-up',
        'sandbag-lunge' => 'lunge',
        'bulgarian-split-squat' => 'lunge',
        'burpee-broad-jump' => 'jumping-jack',
        'ab-wheel' => 'plank',
        'leg-raise' => 'deadbug',
        // advanced → beginner
        'pause-squat' => 'goblet-squat',
        'overhead-squat' => 'goblet-squat',
        'hack-squat' => 'leg-press',
        'deficit-deadlift' => 'glute-bridge',
        'hang-clean' => 'goblet-squat',
        'power-snatch' => 'db-shoulder-press',
        'clean-and-jerk' => 'goblet-squat',
        'weighted-pullup' => 'lat-pulldown',
        'muscle-up' => 'lat-pulldown',
        'weighted-dips' => 'bench-dips',
        'close-grip-bench' => 'db-bench',
        'pendlay-row' => 'db-row',
        'toes-to-bar' => 'deadbug',
        'burpee-pullup' => 'burpee',
        'pistol-squat' => 'bodyweight-squat',
        'shrimp-squat' => 'bodyweight-squat',
        'nordic-curl' => 'leg-curl',
        'box-jump' => 'step-up',
        'handstand-pushup' => 'incline-pushup',
        'archer-pushup' => 'incline-pushup',
        'one-arm-pushup' => 'incline-pushup',
        'plyo-pushup' => 'pushup',
        'dragon-flag' => 'deadbug',
        'l-sit' => 'plank',
        'hollow-rock' => 'deadbug',
        'devil-press' => 'db-shoulder-press',
        'turkish-getup' => 'plank',
        'tuck-jump' => 'jumping-jack',
    ];

    /** Expert → intermediate variant. */
    public const INTERMEDIATE_SUBS = [
        'pclean' => 'kb-swing',
        'hang-clean' => 'kb-swing',
        'power-snatch' => 'kb-swing',
        'clean-and-jerk' => 'thruster',
        'front-squat' => 'squat',
        'pause-squat' => 'squat',
        'overhead-squat' => 'squat',
        'hack-squat' => 'leg-press',
        'deficit-deadlift' => 'deadlift',
        'push-press' => 'ohp',
        'db-snatch' => 'kb-swing',
        'weighted-pullup' => 'pullup',
        'muscle-up' => 'pullup',
        'dips' => 'incline-db-press',
        'weighted-dips' => 'incline-db-press',
        'close-grip-bench' => 'bench',
        'pendlay-row' => 'barbell-row',
        'toes-to-bar' => 'leg-raise',
        'ab-wheel' => 'leg-raise',
        'dragon-flag' => 'leg-raise',
        'l-sit' => 'plank',
        'hollow-rock' => 'plank',
        'burpee-pullup' => 'burpee',
        'burpee-broad-jump' => 'burpee',
        'tuck-jump' => 'burpee',
        'box-jump' => 'step-up',
        'sled-push' => 'farmer',
        'sandbag-lunge' => 'farmer',
        'pistol-squat' => 'bulgarian-split-squat',
        'shrimp-squat' => 'bulgarian-split-squat',
        'nordic-curl' => 'leg-curl',
        'handstand-pushup' => 'pike-pushup',
        'archer-pushup' => 'pushup',
        'one-arm-pushup' => 'pushup',
        'plyo-pushup' => 'pushup',
        'devil-press' => 'thruster',
        'turkish-getup' => 'kb-swing',
    ];

    /** Light starting loads (kg) used when an exercise is replaced. */
    public const START_LOADS = [
        'goblet-squat' => 10, 'db-bench' => 8, 'db-row' => 10, 'db-shoulder-press' => 6, 'lat-pulldown' => 25,
        'glute-bridge' => 0, 'kb-swing' => 12, 'lunge' => 0, 'step-up' => 0,
        'squat' => 40, 'deadlift' => 50, 'bench' => 30, 'ohp' => 20, 'barbell-row' => 30, 'thruster' => 20,
        'leg-press' => 60, 'leg-curl' => 20, 'incline-db-press' => 12,
    ];

    public const BIG_LIFTS = ['squat', 'deadlift', 'front-squat', 'leg-press', 'hipthrust', 'romanian-deadlift'];

    public static function userLevel(?User $user): string
    {
        if (! $user) {
            return 'intermediate';
        }

        return ProgramRecommender::resolvedLevel($user);
    }

    public static function rank(?string $level): int
    {
        return match ($level) {
            'beginner' => 0,
            'intermediate' => 1,
            'advanced', 'expert' => 2,
            default => 1,
        };
    }

    public static function loadStep(string $userLevel, string $exerciseSlug): float
    {
        $big = in_array($exerciseSlug, self::BIG_LIFTS, true);

        return match ($userLevel) {
            'beginner' => 2.5,
            'advanced' => $big ? 2.5 : 1.25,
            default => $big ? 5.0 : 2.5,
        };
    }

    /**
     * @param  array{exerciseId: string, sets: int, reps: int, loadKg: float, restSec: int, kind: string, unitNote: ?string}  $row
     * @return array{exerciseId: string, sets: int, reps: int, loadKg: float, restSec: int, kind: string, unitNote: ?string, adaptedFrom: ?string, adaptation: ?string}
     */
    public static function adapt(array $row, string $userLevel): array
    {
        $row['adaptedFrom'] = null;
        $row['adaptation'] = null;

        $levels = self::levels();
        $userRank = self::rank($userLevel);
        $subs = $userRank === 0 ? self::BEGINNER_SUBS : ($userRank === 1 ? self::INTERMEDIATE_SUBS : []);

        // Follow the substitution chain until the exercise fits the level.
        $slug = $row['exerciseId'];
        $guard = 0;
        while (isset($subs[$slug]) && self::rank($levels[$slug] ?? 'beginner') > $userRank && $guard++ < 3) {
            $slug = $subs[$slug];
        }

        if ($slug !== $row['exerciseId'] && isset($levels[$slug])) {
            $replacement = Exercise::find($slug);
            $row['adaptedFrom'] = $row['exerciseId'];
            $row['adaptation'] = 'Remplacé par '.$replacement?->name.' (adapté à ton niveau)';
            $row['exerciseId'] = $slug;
            $row['kind'] = $replacement?->kind ?? 'load';
            if ($row['kind'] === 'load') {
                $row['loadKg'] = (float) (self::START_LOADS[$slug] ?? 0);
                $row['unitNote'] = null;
            } else {
                $row['loadKg'] = 0;
                $row['unitNote'] = $row['kind'] === 'distance' ? 'm' : null;
                if ($row['kind'] === 'bodyweight' && $row['reps'] > 30) {
                    $row['reps'] = 12;
                }
            }
            if ($slug === 'plank') {
                $row['unitNote'] = 's';
                $row['reps'] = 30;
            }
        }

        if ($userRank === 0) {
            $row['sets'] = min($row['sets'], 3);
            $row['restSec'] = $row['restSec'] + 15;
        }

        return $row;
    }

    /** @return array<string, string> slug => level */
    protected static function levels(): array
    {
        return Exercise::query()->pluck('level', 'slug')->all();
    }
}
