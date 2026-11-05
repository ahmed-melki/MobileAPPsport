<?php

namespace App\Support;

use App\Models\TrainingProgram;
use App\Models\User;
use Illuminate\Support\Collection;

class ProgramRecommender
{
    private const LEVEL_EXACT = 100;
    private const LEVEL_ADJACENT = 20;
    private const GOAL_MATCH = 50;
    private const DAYS_EXACT = 30;
    private const DAYS_STEP = 10;
    private const EQUIPMENT_EXACT = 25;
    private const EQUIPMENT_COMPATIBLE = 8;

    /**
     * @return Collection<int, array{program: TrainingProgram, score: int, reasons: array<int, string>}>
     */
    public static function topFor(User $user, int $limit = 3): Collection
    {
        $programs = TrainingProgram::query()->orderBy('slug')->get();

        return $programs
            ->map(fn (TrainingProgram $program) => self::score($user, $program))
            ->sortByDesc(fn (array $row) => [$row['score'], $row['program']->slug])
            ->values()
            ->take($limit)
            ->values();
    }

    /**
     * @return array{program: TrainingProgram, score: int, reasons: array<int, string>}
     */
    public static function score(User $user, TrainingProgram $program): array
    {
        $score = 0;
        $reasons = [];

        $userLevel = self::resolvedLevel($user);
        $programLevel = strtolower((string) $program->level);
        $levelGap = abs(self::levelRank($userLevel) - self::levelRank($programLevel));

        if ($levelGap === 0) {
            $score += self::LEVEL_EXACT;
            $reasons[] = self::levelReason($programLevel);
        } elseif ($levelGap === 1) {
            $score += self::LEVEL_ADJACENT;
            $reasons[] = 'Proche de ton niveau actuel';
        } else {
            // Beginner ↔ advanced: never a match (too easy or too hard).
            $score -= 200;
        }

        $mainGoal = $user->main_goal;
        $tags = collect($program->goal_tags ?? []);
        if ($mainGoal && $tags->contains($mainGoal)) {
            $score += self::GOAL_MATCH;
            $reasons[] = 'Correspond à ton objectif : '.self::goalLabel($mainGoal);
        }

        if ($user->days_per_week) {
            $diff = abs((int) $program->days_per_week - (int) $user->days_per_week);
            $daysScore = max(0, self::DAYS_EXACT - (self::DAYS_STEP * $diff));
            if ($daysScore > 0) {
                $score += $daysScore;
                if ($diff === 0) {
                    $reasons[] = $program->days_per_week.' séances par semaine comme tu le souhaites';
                } else {
                    $reasons[] = 'Fréquence proche de tes '.$user->days_per_week.' séances par semaine';
                }
            }
        }

        if ($user->equipment) {
            $isGymProgram = $program->equipment === 'gym';

            if ($user->equipment === 'none') {
                if ($program->slug === 'beginner-home-bodyweight') {
                    $score += self::EQUIPMENT_EXACT;
                    $reasons[] = 'Faisable sans matériel (poids du corps)';
                } elseif ($program->equipment === 'home') {
                    $score += self::EQUIPMENT_COMPATIBLE;
                    $reasons[] = 'Faisable à la maison';
                } elseif ($isGymProgram) {
                    $score -= 100;
                }
            } elseif ($user->equipment === 'home') {
                if ($program->equipment === 'home') {
                    $score += self::EQUIPMENT_EXACT;
                    $reasons[] = self::equipmentReason($program->equipment);
                } elseif ($isGymProgram) {
                    $score -= 100;
                }
            } else {
                if ($program->equipment === $user->equipment) {
                    $score += self::EQUIPMENT_EXACT;
                    $reasons[] = self::equipmentReason($program->equipment);
                } elseif (self::equipmentCompatible($user->equipment, $program->equipment)) {
                    $score += self::EQUIPMENT_COMPATIBLE;
                    $reasons[] = 'Réalisable avec ton matériel';
                }
            }

            $score = max(0, $score);
        }

        return [
            'program' => $program,
            'score' => $score,
            'reasons' => $reasons,
        ];
    }

    public static function resolvedLevel(User $user): string
    {
        if ($user->experience_level) {
            return OnboardingGoals::sportLevelFromExperience($user->experience_level);
        }

        return $user->sport_level ?: 'beginner';
    }

    private static function levelRank(string $level): int
    {
        return match ($level) {
            'beginner' => 0,
            'intermediate' => 1,
            'advanced' => 2,
            default => 1,
        };
    }

    private static function levelReason(string $level): string
    {
        return match ($level) {
            'beginner' => 'Adapté aux débutants',
            'intermediate' => 'Adapté au niveau intermédiaire',
            'advanced' => 'Adapté au niveau avancé',
            default => 'Adapté à ton niveau',
        };
    }

    private static function goalLabel(string $goal): string
    {
        return match ($goal) {
            'lose_weight' => 'perte de poids',
            'gain_muscle' => 'prise de masse',
            'clean_bulk' => 'prise de masse propre',
            'maintain' => 'maintien',
            'endurance' => 'endurance',
            default => $goal,
        };
    }

    private static function equipmentReason(?string $equipment): string
    {
        return match ($equipment) {
            'gym' => 'Conçu pour la salle',
            'home' => 'Faisable à la maison',
            'none' => 'Sans matériel',
            default => 'Compatible avec ton matériel',
        };
    }

    private static function equipmentCompatible(string $userEquipment, ?string $programEquipment): bool
    {
        if (! $programEquipment) {
            return false;
        }

        $order = ['none' => 0, 'home' => 1, 'gym' => 2];

        return ($order[$userEquipment] ?? -1) >= ($order[$programEquipment] ?? 99);
    }
}
