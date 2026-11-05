<?php

namespace App\Support;

class OnboardingGoals
{
    public static function fromMainGoal(string $mainGoal): array
    {
        return match ($mainGoal) {
            'lose_weight' => [
                'kind' => 'weight_loss',
                'detail' => 'Perdre du poids progressivement tout en préservant la masse musculaire.',
                'target' => 'Déficit durable et silhouette plus sèche',
            ],
            'gain_muscle' => [
                'kind' => 'mass_gain',
                'detail' => 'Développer la masse musculaire avec une progression régulière sur les composés.',
                'target' => 'Prise de masse et force en hausse',
            ],
            'clean_bulk' => [
                'kind' => 'mass_gain',
                'detail' => 'Prendre du muscle proprement, avec un surplus modéré et un suivi de la composition.',
                'target' => 'Prise de masse contrôlée, minimum de gras',
            ],
            'maintain' => [
                'kind' => 'fitness',
                'detail' => 'Maintenir le poids, la force et une routine d’entraînement régulière.',
                'target' => 'Stabilité du poids et constance des séances',
            ],
            'endurance' => [
                'kind' => 'endurance',
                'detail' => 'Améliorer la capacité cardio et tenir l’effort plus longtemps, sans casser la récupération.',
                'target' => 'Progression d’endurance et volume cardio',
            ],
            default => [
                'kind' => 'fitness',
                'detail' => 'Construire une routine d’entraînement régulière et durable.',
                'target' => '3 à 5 séances par semaine',
            ],
        };
    }

    public static function sportLevelFromExperience(string $experienceLevel): string
    {
        return $experienceLevel === 'expert' ? 'advanced' : $experienceLevel;
    }
}
