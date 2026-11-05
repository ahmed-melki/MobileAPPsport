<?php

namespace App\Support;

use App\Models\Exercise;
use App\Models\SessionExercise;
use App\Models\TrainingProgram;
use App\Models\WorkoutSession;

/**
 * Training programs matched to the user's level.
 *
 *  - Débutant      : light loads, simple / guided movements (machines, haltères, poids du corps),
 *                    3 séries max, more rest.
 *  - Intermédiaire : barbell basics (squat, développé couché, soulevé de terre), more volume.
 *  - Avancé        : heavy loads, technical lifts (power clean, front squat, push press),
 *                    high volume and conditioning.
 *
 * Every beginner session only contains exercises whose level is "beginner".
 */
class TrainingCatalog
{
    /**
     * Exercise row: [exerciseSlug, sets, reps, loadKg, restSec, type]
     * type: load | bw (bodyweight reps) | time (bodyweight seconds) | dist (meters)
     */
    public static function programs(): array
    {
        $all = ['lose_weight', 'maintain', 'gain_muscle', 'clean_bulk', 'endurance'];

        return [
            // ───────────── DÉBUTANT ─────────────
            [
                'slug' => 'beginner-full-body', 'title' => 'Full Body Débutant', 'level' => 'beginner', 'equipment' => 'gym',
                'subtitle' => 'Machines et haltères légers : apprendre les bons gestes, 3 séances par semaine.',
                'weeks' => 8, 'days_per_week' => 3, 'goal_tags' => ['gain_muscle', 'maintain', 'clean_bulk'],
                'sessions' => [
                    ['bfb-a', 'Full Body A', 40, 'Bases jambes & poussée', [['goblet-squat', 3, 10, 10, 90, 'load'], ['db-bench', 3, 10, 8, 90, 'load'], ['seated-cable-row', 3, 12, 25, 75, 'load'], ['plank', 3, 30, 0, 45, 'time']]],
                    ['bfb-b', 'Full Body B', 40, 'Presse & tirage', [['leg-press', 3, 12, 50, 90, 'load'], ['lat-pulldown', 3, 12, 25, 75, 'load'], ['db-shoulder-press', 3, 10, 5, 75, 'load'], ['glute-bridge', 3, 15, 0, 60, 'bw']]],
                    ['bfb-c', 'Full Body C', 40, 'Unilatéral & gainage', [['lunge', 3, 10, 4, 75, 'load'], ['incline-db-press', 3, 10, 6, 75, 'load'], ['db-row', 3, 10, 10, 75, 'load'], ['deadbug', 3, 10, 0, 45, 'bw']]],
                ],
            ],
            [
                'slug' => 'beginner-fat-loss', 'title' => 'Perte de gras Débutant', 'level' => 'beginner', 'equipment' => 'gym',
                'subtitle' => 'Cardio doux + renforcement guidé, pour sécher sans se blesser.',
                'weeks' => 8, 'days_per_week' => 3, 'goal_tags' => ['lose_weight'],
                'sessions' => [
                    ['bfl-a', 'Fat loss A', 35, 'Circuit léger', [['jumping-jack', 3, 30, 0, 45, 'bw'], ['goblet-squat', 3, 12, 8, 60, 'load'], ['incline-pushup', 3, 10, 0, 60, 'bw'], ['plank', 3, 25, 0, 45, 'time']]],
                    ['bfl-b', 'Fat loss B', 35, 'Rameur & dos', [['row', 4, 250, 0, 60, 'dist'], ['step-up', 3, 10, 0, 60, 'bw'], ['lat-pulldown', 3, 12, 20, 60, 'load'], ['deadbug', 3, 10, 0, 45, 'bw']]],
                    ['bfl-c', 'Fat loss C', 35, 'Marche-course & fessiers', [['easy-run', 4, 400, 0, 90, 'dist'], ['glute-bridge', 3, 15, 0, 45, 'bw'], ['mountain-climber', 3, 20, 0, 45, 'bw'], ['side-plank', 2, 20, 0, 45, 'time']]],
                ],
            ],
            [
                'slug' => 'beginner-home-bodyweight', 'title' => 'Full Body Maison Poids du Corps', 'level' => 'beginner', 'equipment' => 'home',
                'subtitle' => 'Trois séances sans matériel : renforcement au poids du corps et mobilité.',
                'weeks' => 6, 'days_per_week' => 3, 'goal_tags' => $all,
                'sessions' => [
                    ['bhb-s1', 'Maison A · Bas du corps & gainage', 30, 'Squats & gainage', [['bodyweight-squat', 3, 12, 0, 60, 'bw'], ['incline-pushup', 3, 10, 0, 60, 'bw'], ['glute-bridge', 3, 15, 0, 45, 'bw'], ['plank', 3, 30, 0, 45, 'time']]],
                    ['bhb-s2', 'Maison B · Cardio & dos', 30, 'Cardio léger', [['jumping-jack', 3, 30, 0, 45, 'bw'], ['lunge', 3, 8, 0, 60, 'bw'], ['superman', 3, 12, 0, 45, 'bw'], ['deadbug', 3, 10, 0, 45, 'bw']]],
                    ['bhb-s3', 'Maison C · Full body express', 30, 'Full body', [['step-up', 3, 10, 0, 60, 'bw'], ['wall-sit', 3, 30, 0, 60, 'time'], ['bench-dips', 3, 8, 0, 60, 'bw'], ['cat-cow', 2, 10, 0, 30, 'bw']]],
                ],
            ],
            [
                'slug' => 'beginner-cardio', 'title' => 'Cardio Débutant', 'level' => 'beginner', 'equipment' => 'home',
                'subtitle' => 'Marche-course et cardio au poids du corps pour construire l’endurance.',
                'weeks' => 6, 'days_per_week' => 3, 'goal_tags' => ['lose_weight', 'endurance', 'maintain'],
                'sessions' => [
                    ['bc-s1', 'Cardio A · Marche-course', 30, 'Intervalles faciles', [['easy-run', 6, 200, 0, 90, 'dist'], ['jumping-jack', 3, 30, 0, 45, 'bw'], ['plank', 3, 20, 0, 45, 'time']]],
                    ['bc-s2', 'Cardio B · Circuit', 25, 'Cardio au poids du corps', [['high-knees', 4, 20, 0, 45, 'bw'], ['bodyweight-squat', 3, 15, 0, 45, 'bw'], ['mountain-climber', 3, 15, 0, 45, 'bw']]],
                    ['bc-s3', 'Cardio C · Endurance', 35, 'Course douce & mobilité', [['easy-run', 4, 400, 0, 90, 'dist'], ['jump-rope', 4, 50, 0, 60, 'bw'], ['worlds-greatest-stretch', 2, 5, 0, 30, 'bw']]],
                ],
            ],

            // ───────────── INTERMÉDIAIRE ─────────────
            [
                'slug' => 'upper-lower', 'title' => 'Upper / Lower', 'level' => 'intermediate', 'equipment' => 'gym',
                'subtitle' => 'Quatre séances, haut et bas du corps en alternance, exercices à la barre.',
                'weeks' => 8, 'days_per_week' => 4, 'goal_tags' => ['gain_muscle', 'maintain'],
                'sessions' => [
                    ['ul-lower', 'Lower', 60, 'Squat & chaîne postérieure', [['squat', 4, 8, 70, 150, 'load'], ['romanian-deadlift', 3, 10, 60, 120, 'load'], ['leg-curl', 3, 12, 35, 75, 'load'], ['calf-raise', 3, 15, 20, 60, 'load'], ['plank', 3, 45, 0, 45, 'time']]],
                    ['ul-upper', 'Upper', 60, 'Développé & rowing', [['bench', 4, 8, 50, 120, 'load'], ['barbell-row', 4, 8, 45, 120, 'load'], ['db-shoulder-press', 3, 10, 14, 90, 'load'], ['biceps-curl', 3, 12, 10, 60, 'load'], ['triceps-pushdown', 3, 12, 20, 60, 'load']]],
                ],
            ],
            [
                'slug' => 'push-pull-legs', 'title' => 'Push / Pull / Legs', 'level' => 'intermediate', 'equipment' => 'gym',
                'subtitle' => 'Volume intermédiaire, 6 séances pour pousser la masse.',
                'weeks' => 8, 'days_per_week' => 6, 'goal_tags' => ['gain_muscle', 'clean_bulk'],
                'sessions' => [
                    ['ppl-legs', 'Legs', 65, 'Quadriceps & ischios', [['squat', 4, 8, 75, 150, 'load'], ['romanian-deadlift', 3, 10, 65, 120, 'load'], ['bulgarian-split-squat', 3, 10, 12, 90, 'load'], ['leg-extension', 3, 12, 40, 60, 'load'], ['calf-raise', 4, 15, 30, 60, 'load']]],
                    ['ppl-pull', 'Pull', 60, 'Dos & biceps', [['pullup', 4, 6, 0, 120, 'bw'], ['barbell-row', 4, 8, 50, 120, 'load'], ['face-pull', 3, 15, 15, 60, 'load'], ['hammer-curl', 3, 12, 12, 60, 'load']]],
                    ['ppl-push', 'Push', 60, 'Pectoraux, épaules, triceps', [['bench', 4, 8, 55, 120, 'load'], ['incline-db-press', 3, 10, 20, 90, 'load'], ['ohp', 3, 8, 35, 120, 'load'], ['lateral-raise', 3, 15, 8, 60, 'load'], ['triceps-pushdown', 3, 12, 25, 60, 'load']]],
                ],
            ],
            [
                'slug' => 'five-five', 'title' => 'Force 5×5', 'level' => 'intermediate', 'equipment' => 'gym',
                'subtitle' => 'A/B à la barre, charges progressives, récup généreuse.',
                'weeks' => 6, 'days_per_week' => 3, 'goal_tags' => ['gain_muscle', 'clean_bulk'],
                'sessions' => [
                    ['f5-a', 'Séance A · Squat / bench', 55, 'Force bas & haut', [['squat', 5, 5, 70, 180, 'load'], ['bench', 5, 5, 50, 150, 'load'], ['barbell-row', 5, 5, 45, 120, 'load']]],
                    ['f5-b', 'Séance B · Deadlift / press', 55, 'Force chaîne postérieure', [['squat', 5, 5, 70, 180, 'load'], ['ohp', 5, 5, 32.5, 150, 'load'], ['deadlift', 1, 5, 90, 180, 'load']]],
                ],
            ],
            [
                'slug' => 'home-dumbbell-full-body', 'title' => 'Full Body Haltères Maison', 'level' => 'intermediate', 'equipment' => 'home',
                'subtitle' => 'Quatre séances avec haltères et kettlebell à la maison.',
                'weeks' => 8, 'days_per_week' => 4, 'goal_tags' => ['gain_muscle', 'clean_bulk', 'maintain', 'lose_weight'],
                'sessions' => [
                    ['hdfb-s1', 'Haltères A · Haut du corps', 50, 'Poussée & tirage', [['pushup', 4, 15, 0, 75, 'bw'], ['db-row', 4, 10, 16, 75, 'load'], ['db-shoulder-press', 3, 10, 12, 75, 'load'], ['biceps-curl', 3, 12, 10, 60, 'load']]],
                    ['hdfb-s2', 'Haltères B · Bas du corps', 50, 'Jambes & fessiers', [['goblet-squat', 4, 12, 20, 90, 'load'], ['romanian-deadlift', 3, 12, 20, 90, 'load'], ['bulgarian-split-squat', 3, 10, 10, 75, 'load'], ['calf-raise', 3, 15, 10, 45, 'load']]],
                    ['hdfb-s3', 'Haltères C · Métabolique', 40, 'Full body intense', [['thruster', 4, 10, 10, 75, 'load'], ['kb-swing', 4, 15, 16, 60, 'load'], ['russian-twist', 3, 20, 0, 45, 'bw'], ['mountain-climber', 3, 30, 0, 45, 'bw']]],
                    ['hdfb-s4', 'Haltères D · Unilatéral & grip', 45, 'Fentes & portés', [['lunge', 3, 12, 10, 75, 'load'], ['pike-pushup', 3, 8, 0, 75, 'bw'], ['overhead-triceps', 3, 12, 10, 60, 'load'], ['farmer', 4, 40, 16, 60, 'dist']]],
                ],
            ],
            [
                'slug' => 'intermediate-fat-loss', 'title' => 'Sèche Intermédiaire', 'level' => 'intermediate', 'equipment' => 'gym',
                'subtitle' => 'Force + HIIT, 4 séances pour perdre du gras en gardant le muscle.',
                'weeks' => 8, 'days_per_week' => 4, 'goal_tags' => ['lose_weight', 'maintain'],
                'sessions' => [
                    ['ifl-a', 'Sèche A · Kettlebell & rameur', 45, 'Circuit force-cardio', [['kb-swing', 4, 15, 16, 60, 'load'], ['goblet-squat', 4, 12, 16, 60, 'load'], ['pushup', 4, 12, 0, 60, 'bw'], ['row', 4, 500, 0, 90, 'dist']]],
                    ['ifl-b', 'Sèche B · Thrusters & tirage', 45, 'Full body', [['thruster', 4, 10, 20, 75, 'load'], ['lat-pulldown', 4, 10, 40, 75, 'load'], ['mountain-climber', 4, 30, 0, 45, 'bw'], ['bike', 4, 1000, 0, 60, 'dist']]],
                    ['ifl-c', 'Sèche C · Chaîne postérieure', 45, 'Fessiers & gainage', [['romanian-deadlift', 3, 10, 50, 90, 'load'], ['step-up', 3, 12, 8, 60, 'load'], ['burpee', 4, 10, 0, 60, 'bw'], ['plank', 3, 45, 0, 45, 'time']]],
                    ['ifl-d', 'Sèche D · HIIT', 35, 'Intervalles', [['run', 6, 400, 0, 90, 'dist'], ['jump-rope', 5, 100, 0, 45, 'bw'], ['russian-twist', 3, 20, 0, 45, 'bw']]],
                ],
            ],
            [
                'slug' => 'intermediate-endurance', 'title' => 'Endurance Intermédiaire', 'level' => 'intermediate', 'equipment' => 'gym',
                'subtitle' => 'Course, rameur et renforcement pour progresser en cardio.',
                'weeks' => 8, 'days_per_week' => 4, 'goal_tags' => ['endurance', 'lose_weight'],
                'sessions' => [
                    ['ie-a', 'Endurance A · Fractionné', 45, 'Course', [['run', 6, 400, 0, 90, 'dist'], ['goblet-squat', 3, 15, 16, 60, 'load'], ['plank', 3, 45, 0, 45, 'time']]],
                    ['ie-b', 'Endurance B · Rameur', 45, 'Rameur & dos', [['row', 5, 500, 0, 90, 'dist'], ['db-row', 3, 12, 16, 60, 'load'], ['step-up', 3, 12, 8, 60, 'load']]],
                    ['ie-c', 'Endurance C · Stations', 45, 'Circuit type Hyrox', [['ski', 5, 300, 0, 75, 'dist'], ['farmer', 4, 40, 20, 60, 'dist'], ['wallball', 3, 15, 6, 60, 'load']]],
                    ['ie-d', 'Endurance D · Sortie longue', 50, 'Course continue', [['easy-run', 1, 6000, 0, 0, 'dist'], ['worlds-greatest-stretch', 2, 5, 0, 30, 'bw']]],
                ],
            ],

            // ───────────── AVANCÉ ─────────────
            [
                'slug' => 'hyrox-engine', 'title' => 'Hyrox Engine', 'level' => 'advanced', 'equipment' => 'gym',
                'subtitle' => 'Force lourde + stations Hyrox, 8 semaines pour la compétition.',
                'weeks' => 8, 'days_per_week' => 4, 'goal_tags' => ['endurance'],
                'sessions' => [
                    ['hyrox-s1', 'S1 · Lower power', 62, 'Squat & hanches', [['squat', 4, 6, 90, 150, 'load'], ['hipthrust', 3, 10, 80, 90, 'load'], ['deadlift', 3, 5, 100, 150, 'load'], ['ab-wheel', 3, 10, 0, 45, 'bw']]],
                    ['hyrox-s2', 'S2 · Engine', 48, 'Ski / rameur / course', [['ski', 4, 500, 0, 90, 'dist'], ['row', 4, 500, 0, 90, 'dist'], ['run', 5, 400, 0, 75, 'dist']]],
                    ['hyrox-s3', 'S3 · Upper + carries', 55, 'Haut du corps & portés', [['bench', 4, 6, 52.5, 120, 'load'], ['pullup', 4, 6, 6, 120, 'load'], ['farmer', 4, 40, 24, 60, 'dist'], ['wallball', 3, 20, 6, 60, 'load']]],
                    ['hyrox-s4', 'S4 · Mixed piece', 45, 'Simulation course', [['sled-push', 4, 25, 0, 90, 'dist'], ['sandbag-lunge', 3, 40, 0, 90, 'dist'], ['burpee-broad-jump', 3, 40, 0, 90, 'dist'], ['ski', 3, 250, 0, 60, 'dist']]],
                ],
            ],
            [
                'slug' => 'advanced-strength', 'title' => 'Force Avancée', 'level' => 'advanced', 'equipment' => 'gym',
                'subtitle' => 'Charges lourdes, mouvements techniques (power clean, front squat, push press).',
                'weeks' => 8, 'days_per_week' => 4, 'goal_tags' => ['gain_muscle', 'clean_bulk', 'maintain'],
                'sessions' => [
                    ['as-a', 'Force A · Squat & bench lourds', 70, 'Force maximale', [['squat', 5, 3, 100, 180, 'load'], ['bench', 5, 3, 75, 180, 'load'], ['pullup', 4, 8, 10, 120, 'load']]],
                    ['as-b', 'Force B · Deadlift & press', 70, 'Chaîne postérieure', [['deficit-deadlift', 5, 3, 120, 210, 'load'], ['ohp', 5, 3, 50, 150, 'load'], ['pendlay-row', 4, 6, 70, 120, 'load'], ['weighted-pullup', 4, 5, 15, 150, 'load']]],
                    ['as-c', 'Force C · Front squat & push press', 65, 'Puissance', [['front-squat', 4, 4, 80, 180, 'load'], ['push-press', 4, 4, 55, 150, 'load'], ['dips', 4, 10, 10, 90, 'load']]],
                    ['as-d', 'Force D · Haltéro', 60, 'Explosivité', [['pclean', 6, 2, 60, 150, 'load'], ['hang-clean', 4, 3, 55, 150, 'load'], ['clean-and-jerk', 4, 2, 60, 180, 'load'], ['toes-to-bar', 3, 10, 0, 60, 'bw']]],
                ],
            ],
            [
                'slug' => 'advanced-hypertrophy', 'title' => 'Hypertrophie Avancée', 'level' => 'advanced', 'equipment' => 'gym',
                'subtitle' => 'Gros volume, 5 séances par groupe musculaire pour une prise de masse sérieuse.',
                'weeks' => 10, 'days_per_week' => 5, 'goal_tags' => ['gain_muscle', 'clean_bulk'],
                'sessions' => [
                    ['ah-1', 'Hyper 1 · Pectoraux & triceps', 70, 'Poussée', [['bench', 5, 8, 75, 120, 'load'], ['incline-db-press', 4, 10, 28, 90, 'load'], ['weighted-dips', 4, 10, 15, 90, 'load'], ['close-grip-bench', 3, 8, 60, 90, 'load'], ['cable-fly', 3, 15, 15, 60, 'load'], ['overhead-triceps', 3, 12, 20, 60, 'load']]],
                    ['ah-2', 'Hyper 2 · Dos & biceps', 70, 'Tirage', [['weighted-pullup', 5, 8, 10, 120, 'load'], ['pendlay-row', 4, 8, 70, 120, 'load'], ['seated-cable-row', 4, 10, 60, 90, 'load'], ['barbell-curl', 4, 10, 30, 60, 'load']]],
                    ['ah-3', 'Hyper 3 · Jambes', 75, 'Quadriceps & ischios', [['pause-squat', 5, 6, 90, 150, 'load'], ['hack-squat', 4, 10, 120, 120, 'load'], ['romanian-deadlift', 4, 10, 90, 120, 'load'], ['bulgarian-split-squat', 4, 10, 20, 90, 'load'], ['leg-extension', 3, 15, 50, 60, 'load'], ['calf-raise', 4, 15, 40, 60, 'load']]],
                    ['ah-4', 'Hyper 4 · Épaules & bras', 60, 'Épaules', [['ohp', 5, 6, 50, 120, 'load'], ['lateral-raise', 4, 15, 10, 60, 'load'], ['face-pull', 4, 15, 20, 60, 'load'], ['hammer-curl', 3, 12, 16, 60, 'load']]],
                    ['ah-5', 'Hyper 5 · Full body lourd', 60, 'Force-volume', [['deadlift', 4, 5, 140, 180, 'load'], ['front-squat', 3, 8, 70, 150, 'load'], ['ab-wheel', 3, 15, 0, 60, 'bw']]],
                ],
            ],
            [
                'slug' => 'advanced-shred', 'title' => 'Sèche Avancée', 'level' => 'advanced', 'equipment' => 'gym',
                'subtitle' => 'Conditionnement intense + force pour sécher en gardant la performance.',
                'weeks' => 8, 'days_per_week' => 5, 'goal_tags' => ['lose_weight', 'endurance'],
                'sessions' => [
                    ['ash-1', 'Shred 1 · Thrusters & tractions', 50, 'Métabolique', [['thruster', 5, 10, 35, 75, 'load'], ['muscle-up', 5, 5, 0, 90, 'bw'], ['burpee-pullup', 4, 12, 0, 75, 'bw'], ['burpee-broad-jump', 4, 20, 0, 75, 'dist'], ['row', 5, 500, 0, 75, 'dist']]],
                    ['ash-2', 'Shred 2 · Kettlebell & ski', 45, 'Puissance-cardio', [['kb-swing', 5, 20, 24, 60, 'load'], ['front-squat', 4, 8, 60, 120, 'load'], ['ski', 5, 300, 0, 60, 'dist']]],
                    ['ash-3', 'Shred 3 · Force & sled', 55, 'Force', [['deadlift', 4, 6, 120, 150, 'load'], ['push-press', 4, 6, 50, 120, 'load'], ['sled-push', 5, 20, 0, 90, 'dist']]],
                    ['ash-4', 'Shred 4 · Course & burpees', 45, 'HIIT', [['run', 8, 400, 0, 75, 'dist'], ['box-jump', 5, 12, 0, 60, 'bw'], ['tuck-jump', 4, 15, 0, 60, 'bw'], ['ab-wheel', 3, 15, 0, 45, 'bw']]],
                    ['ash-5', 'Shred 5 · Haltéro & fentes', 50, 'Full body', [['power-snatch', 5, 3, 45, 120, 'load'], ['overhead-squat', 4, 5, 40, 120, 'load'], ['sandbag-lunge', 4, 40, 0, 90, 'dist'], ['mountain-climber', 4, 40, 0, 45, 'bw']]],
                ],
            ],
            [
                'slug' => 'advanced-home-athlete', 'title' => 'Athlète Maison Avancé', 'level' => 'advanced', 'equipment' => 'home',
                'subtitle' => 'Haltères lourds, pliométrie et gainage avancé, sans salle.',
                'weeks' => 8, 'days_per_week' => 4, 'goal_tags' => $all,
                'sessions' => [
                    ['aha-1', 'Maison+ A · Force', 55, 'Haut & bas du corps', [['handstand-pushup', 5, 6, 0, 120, 'bw'], ['pistol-squat', 5, 6, 0, 90, 'bw'], ['nordic-curl', 4, 6, 0, 120, 'bw'], ['dragon-flag', 4, 6, 0, 90, 'bw']]],
                    ['aha-2', 'Maison+ B · Explosivité', 45, 'Pliométrie', [['plyo-pushup', 5, 10, 0, 75, 'bw'], ['box-jump', 5, 10, 0, 75, 'bw'], ['devil-press', 5, 10, 15, 90, 'load'], ['tuck-jump', 4, 15, 0, 60, 'bw']]],
                    ['aha-3', 'Maison+ C · Volume', 50, 'Poussée & jambes', [['archer-pushup', 5, 8, 0, 75, 'bw'], ['shrimp-squat', 5, 8, 0, 75, 'bw'], ['one-arm-pushup', 4, 5, 0, 90, 'bw'], ['l-sit', 4, 20, 0, 60, 'time']]],
                    ['aha-4', 'Maison+ D · Métabolique', 45, 'Conditionnement', [['turkish-getup', 4, 3, 16, 90, 'load'], ['kb-swing', 5, 20, 24, 60, 'load'], ['hollow-rock', 4, 20, 0, 45, 'bw'], ['side-plank', 3, 60, 0, 45, 'time'], ['mountain-climber', 4, 40, 0, 45, 'bw']]],
                ],
            ],
        ];
    }

    public static function ensureSeeded(): void
    {
        ExerciseLibrary::seed();

        foreach (self::programs() as $data) {
            $sessions = $data['sessions'];
            unset($data['sessions']);

            $program = TrainingProgram::updateOrCreate(['slug' => $data['slug']], $data);

            $keep = [];
            foreach ($sessions as [$slug, $title, $duration, $focus, $exercises]) {
                $keep[] = $slug;
                WorkoutSession::updateOrCreate(['slug' => $slug], [
                    'program_slug' => $program->slug,
                    'title' => $title,
                    'duration_min' => $duration,
                    'focus' => $focus,
                ]);

                // Rebuild the exercise list so its order and content always match the catalog.
                SessionExercise::query()->where('session_slug', $slug)->delete();
                foreach ($exercises as [$exercise, $sets, $reps, $load, $rest, $type]) {
                    self::ensureExercise($exercise);
                    SessionExercise::create([
                        'session_slug' => $slug,
                        'exercise_slug' => $exercise,
                        'sets' => $sets,
                        'reps' => $reps,
                        'load_kg' => $load,
                        'rest_sec' => $rest,
                        'kind' => match ($type) {
                            'dist' => 'distance',
                            'bw', 'time' => 'bodyweight',
                            default => 'load',
                        },
                        'unit_note' => match ($type) {
                            'dist' => 'm',
                            'time' => 's',
                            default => null,
                        },
                    ]);
                }
            }

            // Remove old sessions of this program that are no longer in the catalog.
            WorkoutSession::query()->where('program_slug', $program->slug)->whereNotIn('slug', $keep)->delete();
        }
    }

    public static function ensureExercise(string $slug): Exercise
    {
        $exercise = Exercise::find($slug);

        if ($exercise) {
            return $exercise;
        }

        return Exercise::create([
            'slug' => $slug,
            'name' => ucfirst(str_replace(['-', '_'], ' ', $slug)),
            'category' => 'strength',
            'equipment' => 'Poids du corps',
            'muscles' => 'Général',
            'cue' => 'Suis les consignes du coach.',
            'last_perf' => null,
        ]);
    }
}
