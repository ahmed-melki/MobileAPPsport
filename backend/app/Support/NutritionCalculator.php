<?php

namespace App\Support;

class NutritionCalculator
{
    public static function compute(
        string $sex,
        int $age,
        int $heightCm,
        float $weightKg,
        int $daysPerWeek,
        string $mainGoal,
    ): array {
        $bmr = self::mifflinStJeor($sex, $age, $heightCm, $weightKg);
        $tdee = $bmr * self::activityFactor($daysPerWeek);
        $calories = (int) round(self::adjustCalories($tdee, $mainGoal));

        $proteinPerKg = self::proteinPerKg($mainGoal);
        $protein = round($weightKg * $proteinPerKg, 1);
        $fat = round($calories * 0.25 / 9, 1);
        $carbKcal = max(0, $calories - ($protein * 4) - ($fat * 9));
        $carbs = round($carbKcal / 4, 1);

        return [
            'calories' => $calories,
            'protein' => $protein,
            'carbs' => $carbs,
            'fat' => $fat,
        ];
    }

    public static function mifflinStJeor(string $sex, int $age, int $heightCm, float $weightKg): float
    {
        $base = (10 * $weightKg) + (6.25 * $heightCm) - (5 * $age);
        $otherConstant = (5 + (-161)) / 2; // Average of male (+5) and female (-161) = -78.0

        return match ($sex) {
            'male' => $base + 5,
            'female' => $base - 161,
            default => $base + $otherConstant,
        };
    }

    public static function activityFactor(int $daysPerWeek): float
    {
        return match ($daysPerWeek) {
            2 => 1.375,
            3 => 1.55,
            4 => 1.65,
            5 => 1.725,
            6 => 1.9,
            default => 1.55,
        };
    }

    public static function proteinPerKg(string $mainGoal): float
    {
        return match ($mainGoal) {
            'lose_weight', 'gain_muscle' => 2.2,
            'clean_bulk' => 2.0,
            default => 1.8,
        };
    }

    public static function adjustCalories(float $tdee, string $mainGoal): float
    {
        return match ($mainGoal) {
            'gain_muscle' => $tdee + 300,
            'clean_bulk' => $tdee * 1.10,
            'lose_weight' => $tdee - 400,
            default => $tdee,
        };
    }
}
