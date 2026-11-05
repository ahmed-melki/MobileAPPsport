<?php

namespace App\Support;

use App\Models\User;
use Illuminate\Support\Facades\DB;

class OnboardingService
{
    public function complete(User $user, array $payload): User
    {
        return DB::transaction(function () use ($user, $payload) {
            $experienceLevel = $payload['experienceLevel'];
            $sportLevel = OnboardingGoals::sportLevelFromExperience($experienceLevel);

            $user->fill([
                'sex' => $payload['sex'],
                'age' => $payload['age'],
                'height_cm' => $payload['heightCm'],
                'main_goal' => $payload['mainGoal'],
                'experience_level' => $experienceLevel,
                'sport_level' => $sportLevel,
                'days_per_week' => $payload['daysPerWeek'],
                'equipment' => $payload['equipment'],
                'onboarding_completed_at' => now(),
            ]);
            $user->save();

            $user->measurements()->updateOrCreate(
                ['measured_at' => now()->toDateString()],
                ['weight_kg' => $payload['weightKg']]
            );

            $user->goals()->where('is_primary', true)->update(['is_primary' => false]);

            $goal = OnboardingGoals::fromMainGoal($payload['mainGoal']);
            $user->goals()->create([
                'kind' => $goal['kind'],
                'detail' => $goal['detail'],
                'target' => $goal['target'],
                'deadline' => null,
                'progress' => 0,
                'is_active' => true,
                'is_primary' => true,
            ]);

            $targets = NutritionCalculator::compute(
                $payload['sex'],
                (int) $payload['age'],
                (int) $payload['heightCm'],
                (float) $payload['weightKg'],
                (int) $payload['daysPerWeek'],
                $payload['mainGoal'],
            );

            $user->nutritionTarget()->updateOrCreate([], $targets);
            $user->unsetRelation('nutritionTarget');

            return $user->fresh(['sports']);
        });
    }
}
