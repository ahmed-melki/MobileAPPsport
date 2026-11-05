<?php

namespace App\Support;

use App\Http\Resources\RecommendedProgramResource;
use App\Models\Exercise;
use App\Models\Food;
use App\Models\Recipe;
use App\Models\User;
use Illuminate\Support\Facades\Cache;

/**
 * AI recommendations (training + nutrition).
 *
 * 1. A rule engine computes a complete, personalised recommendation from the
 *    user's goal, level, frequency, equipment and real data (logs, meals).
 * 2. If an AI key is configured (Gemini / OpenAI-compatible), the LLM receives
 *    this context and writes the personalised summary + tips in French.
 * 3. Without a key (or if the AI fails), the rule texts are returned:
 *    the app always works.
 */
class AiAdvisor
{
    public const GOAL_LABELS = [
        'lose_weight' => 'Perte de poids',
        'gain_muscle' => 'Prise de muscle',
        'clean_bulk' => 'Prise de masse propre',
        'maintain' => 'Maintien / forme',
        'endurance' => 'Endurance',
    ];

    public const LEVEL_LABELS = [
        'beginner' => 'Débutant',
        'intermediate' => 'Intermédiaire',
        'advanced' => 'Avancé',
    ];

    /** Muscle groups to prioritise per goal. */
    private const GOAL_MUSCLES = [
        'gain_muscle' => ['chest', 'back', 'legs', 'shoulders', 'arms', 'glutes'],
        'clean_bulk' => ['legs', 'back', 'chest', 'shoulders', 'glutes', 'arms'],
        'lose_weight' => ['full_body', 'legs', 'cardio', 'core', 'back', 'chest'],
        'endurance' => ['cardio', 'full_body', 'legs', 'core', 'back', 'mobility'],
        'maintain' => ['legs', 'chest', 'back', 'core', 'full_body', 'mobility'],
    ];

    private const MUSCLE_LABELS = [
        'chest' => 'pectoraux', 'back' => 'dos', 'shoulders' => 'épaules', 'arms' => 'bras', 'legs' => 'jambes',
        'glutes' => 'fessiers', 'core' => 'gainage', 'full_body' => 'corps entier', 'cardio' => 'cardio', 'mobility' => 'mobilité',
    ];

    // ───────────────────────────── TRAINING ─────────────────────────────

    public static function training(User $user): array
    {
        $level = ProgramRecommender::resolvedLevel($user);
        $goal = $user->main_goal ?: 'maintain';
        $days = (int) ($user->days_per_week ?: ['beginner' => 3, 'intermediate' => 4, 'advanced' => 5][$level] ?? 3);
        $home = in_array($user->equipment, ['none', 'home', 'home_basic'], true);

        $plan = self::trainingPlan($goal, $level, $days);
        $programs = ProgramRecommender::topFor($user, 3)
            ->map(fn ($row) => (new RecommendedProgramResource($row))->resolve())
            ->values()->all();
        $exercises = self::pickExercises($goal, $level, $home);

        $lastWeek = $user->sessionLogs()->where('date', '>=', now()->subDays(7)->toDateString())->count();
        $rules = self::trainingRules($goal, $level, $days, $lastWeek);

        $context = [
            'objectif' => self::GOAL_LABELS[$goal] ?? $goal,
            'niveau' => self::LEVEL_LABELS[$level] ?? $level,
            'seances_souhaitees_par_semaine' => $days,
            'materiel' => $home ? 'maison' : 'salle',
            'seances_faites_7_derniers_jours' => $lastWeek,
            'plan' => $plan,
            'programmes_recommandes' => array_map(fn ($p) => $p['title'], $programs),
            'exercices_recommandes' => array_map(fn ($e) => $e['name'], $exercises),
        ];

        $ai = self::askAi(
            'training',
            $user,
            $context,
            "Tu es le coach sportif IA de l'application Apex. Tu parles français, tu tutoies, tu es motivant et précis. "
            ."Tu adaptes STRICTEMENT tes conseils au niveau (débutant = léger, technique, peu de volume ; intermédiaire = progression ; "
            ."avancé = charges lourdes, volume élevé, techniques avancées) et à l'objectif de l'utilisateur. Pas de conseils médicaux."
        );

        return [
            'source' => $ai ? 'ai' : 'rules',
            'goal' => $goal,
            'goalLabel' => self::GOAL_LABELS[$goal] ?? $goal,
            'level' => $level,
            'levelLabel' => self::LEVEL_LABELS[$level] ?? $level,
            'summary' => $ai['summary'] ?? $rules['summary'],
            'tips' => $ai['tips'] ?? $rules['tips'],
            'plan' => $plan,
            'programs' => $programs,
            'exercises' => $exercises,
            'sessionsLast7Days' => $lastWeek,
        ];
    }

    /** Sets / reps / rest / intensity / cardio for a goal × level. */
    public static function trainingPlan(string $goal, string $level, int $days): array
    {
        $reps = match ($goal) {
            'gain_muscle', 'clean_bulk' => '8–12',
            'lose_weight' => '12–15',
            'endurance' => '15–20',
            default => '10–12',
        };
        if ($level === 'advanced' && in_array($goal, ['gain_muscle', 'clean_bulk'], true)) {
            $reps = '5–8 (lourd) + 10–12 (volume)';
        }

        $sets = ['beginner' => '2–3', 'intermediate' => '3–4', 'advanced' => '4–5'][$level] ?? '3';
        $exercisesPerSession = ['beginner' => 4, 'intermediate' => 5, 'advanced' => 6][$level] ?? 5;

        $rest = match ($goal) {
            'gain_muscle', 'clean_bulk' => $level === 'advanced' ? '90–180 s' : '90–120 s',
            'lose_weight' => '45–60 s',
            'endurance' => '30–45 s',
            default => '60–90 s',
        };

        $intensity = [
            'beginner' => 'Léger à modéré : garde 3–4 répétitions en réserve, la technique avant la charge.',
            'intermediate' => 'Modéré à difficile : 2 répétitions en réserve, augmente la charge chaque semaine.',
            'advanced' => 'Difficile : 0–1 répétition en réserve sur les dernières séries, cycles lourds / légers.',
        ][$level];

        $cardio = match ($goal) {
            'lose_weight' => ['beginner' => '3 × 20 min de marche rapide ou vélo', 'intermediate' => '3 × 25 min dont 1 séance fractionnée', 'advanced' => '2 HIIT de 20 min + 2 × 30 min zone 2'][$level],
            'endurance' => ['beginner' => '3 × 20 min en aisance respiratoire', 'intermediate' => '3–4 sorties dont 1 fractionné', 'advanced' => '4–5 séances : fractionné, tempo, sortie longue'][$level],
            'gain_muscle', 'clean_bulk' => '2 × 15–20 min légers pour la santé du cœur',
            default => '2 × 20–30 min',
        };

        return [
            'daysPerWeek' => $days,
            'exercisesPerSession' => $exercisesPerSession,
            'sets' => $sets,
            'reps' => $reps,
            'rest' => $rest,
            'intensity' => $intensity,
            'cardio' => $cardio,
            'duration' => ['beginner' => '35–45 min', 'intermediate' => '45–60 min', 'advanced' => '60–75 min'][$level],
        ];
    }

    /** Exercises of the user's exact level, one per prioritised muscle group. */
    public static function pickExercises(string $goal, string $level, bool $home): array
    {
        $levels = $level === 'advanced' ? ['advanced', 'expert'] : [$level];
        $pool = Exercise::query()->whereIn('level', $levels)->get();
        if ($home) {
            $homePool = $pool->where('at_home', true);
            $pool = $homePool->isNotEmpty() ? $homePool : $pool;
        } else {
            // In the gym: gym exercises first, home ones as a backup.
            $pool = $pool->sortBy(fn ($e) => $e->at_home ? 1 : 0);
        }

        $picked = collect();
        foreach (self::GOAL_MUSCLES[$goal] ?? self::GOAL_MUSCLES['maintain'] as $group) {
            $exercise = $pool->first(fn ($e) => $e->muscle_group === $group && ! $picked->contains('slug', $e->slug));
            if ($exercise) {
                $picked->push($exercise);
            }
        }
        foreach ($pool as $exercise) {
            if ($picked->count() >= 6) {
                break;
            }
            if (! $picked->contains('slug', $exercise->slug)) {
                $picked->push($exercise);
            }
        }

        return $picked->take(6)->map(fn (Exercise $e) => [
            'id' => $e->slug,
            'name' => $e->name,
            'muscleGroup' => $e->muscle_group,
            'level' => $e->level === 'expert' ? 'advanced' : $e->level,
            'atHome' => (bool) $e->at_home,
            'equipment' => $e->equipment,
            'why' => 'Travaille '.(self::MUSCLE_LABELS[$e->muscle_group] ?? $e->muscle_group).' · adapté '.(self::LEVEL_LABELS[$level] ?? $level),
        ])->values()->all();
    }

    private static function trainingRules(string $goal, string $level, int $days, int $lastWeek): array
    {
        $goalLabel = mb_strtolower(self::GOAL_LABELS[$goal] ?? $goal);
        $levelLabel = mb_strtolower(self::LEVEL_LABELS[$level] ?? $level);

        $summary = match ($level) {
            'beginner' => "Niveau {$levelLabel} avec un objectif de {$goalLabel} : on construit les bases. Des séances courtes et légères, des mouvements simples (machines, haltères, poids du corps) et une technique propre avant d'ajouter du poids.",
            'intermediate' => "Niveau {$levelLabel} avec un objectif de {$goalLabel} : tu as les bases, maintenant on progresse. Plus de volume, des charges qui augmentent chaque semaine et des exercices libres (squat, développé, tractions).",
            default => "Niveau {$levelLabel} avec un objectif de {$goalLabel} : tu as de l'expérience, on pousse fort. Mouvements techniques (haltérophilie, lestés, unilatéraux), charges lourdes et périodisation pour continuer à progresser.",
        };

        $tips = [
            'beginner' => ['Commence chaque séance par 5–10 min d’échauffement.', 'Filme-toi ou demande un avis pour vérifier ta technique.', 'Ajoute 1–2 kg seulement quand toutes les répétitions sont faciles.'],
            'intermediate' => ['Note tes charges : vise +2,5 à +5 kg ou +1 répétition chaque semaine.', 'Alterne une semaine plus légère toutes les 4–6 semaines.', 'Garde 1–2 exercices de base fixes pour mesurer tes progrès.'],
            'advanced' => ['Périodise : 3 semaines lourdes puis 1 semaine de décharge.', 'Travaille les points faibles avec des variantes (pause, déficit, lest).', 'Surveille récupération et sommeil : c’est là que tu progresses.'],
        ][$level] ?? [];

        $tips[] = match ($goal) {
            'lose_weight' => 'Garde un léger déficit calorique et reste actif hors séance (8–10 000 pas).',
            'gain_muscle', 'clean_bulk' => 'Mange assez de protéines (1,6–2 g/kg) et un léger surplus calorique.',
            'endurance' => 'Fais 80 % de ton cardio à allure facile et 20 % intense.',
            default => 'La régularité compte plus que l’intensité : tiens ton planning.',
        };

        if ($lastWeek === 0) {
            $tips[] = "Aucune séance ces 7 derniers jours : reprends avec une séance facile dès aujourd'hui.";
        } elseif ($lastWeek < $days) {
            $tips[] = "{$lastWeek} séance(s) sur {$days} cette semaine : encore un petit effort pour tenir ton objectif.";
        } else {
            $tips[] = "Bravo, {$lastWeek} séances cette semaine : objectif tenu, pense à bien récupérer.";
        }

        return ['summary' => $summary, 'tips' => $tips];
    }

    // ───────────────────────────── NUTRITION ─────────────────────────────

    public static function nutrition(User $user, ?int $hour = null): array
    {
        $goal = $user->main_goal ?: 'maintain';
        $level = ProgramRecommender::resolvedLevel($user);
        $hour ??= (int) now()->format('G');
        $target = $user->nutritionTarget;
        $targets = [
            'calories' => (int) ($target->calories ?? 2200),
            'protein' => (float) ($target->protein ?? 140),
            'carbs' => (float) ($target->carbs ?? 230),
            'fat' => (float) ($target->fat ?? 70),
        ];

        $meals = $user->mealEntries()->whereDate('date', now()->toDateString())->get();
        $today = [
            'calories' => (int) $meals->sum('calories'),
            'protein' => round((float) $meals->sum('protein'), 1),
            'carbs' => round((float) $meals->sum('carbs'), 1),
            'fat' => round((float) $meals->sum('fat'), 1),
        ];
        $remaining = [
            'calories' => max(0, $targets['calories'] - $today['calories']),
            'protein' => max(0, round($targets['protein'] - $today['protein'], 1)),
            'carbs' => max(0, round($targets['carbs'] - $today['carbs'], 1)),
            'fat' => max(0, round($targets['fat'] - $today['fat'], 1)),
        ];

        $nextMeal = match (true) {
            $hour < 10 => 'breakfast',
            $hour < 15 => 'lunch',
            $hour < 18 => 'snack',
            default => 'dinner',
        };

        $recipes = self::pickRecipes($goal, $nextMeal, $remaining);
        $foods = self::pickFoods($goal, $remaining);
        $rules = self::nutritionRules($goal, $targets, $today, $remaining, $meals->count());

        $context = [
            'objectif' => self::GOAL_LABELS[$goal] ?? $goal,
            'niveau_sportif' => self::LEVEL_LABELS[$level] ?? $level,
            'objectifs_journaliers' => $targets,
            'mange_aujourdhui' => $today,
            'reste_a_manger' => $remaining,
            'prochain_repas' => $nextMeal,
            'recettes_proposees' => array_map(fn ($r) => $r['name'].' ('.$r['calories'].' kcal)', $recipes),
            'aliments_proposes' => array_map(fn ($f) => $f['name'], $foods),
        ];

        $ai = self::askAi(
            'nutrition',
            $user,
            $context,
            "Tu es le nutritionniste IA de l'application Apex. Tu parles français, tu tutoies. Tu proposes uniquement une alimentation saine "
            ."(aliments complets, protéines maigres, légumes, bons gras), adaptée à l'objectif et à ce qui reste à manger aujourd'hui. Pas de conseils médicaux."
        );

        return [
            'source' => $ai ? 'ai' : 'rules',
            'goal' => $goal,
            'goalLabel' => self::GOAL_LABELS[$goal] ?? $goal,
            'nextMeal' => $nextMeal,
            'summary' => $ai['summary'] ?? $rules['summary'],
            'tips' => $ai['tips'] ?? $rules['tips'],
            'targets' => $targets,
            'today' => $today,
            'remaining' => $remaining,
            'recipes' => $recipes,
            'foods' => $foods,
        ];
    }

    private static function pickRecipes(string $goal, string $mealType, array $remaining): array
    {
        $budget = max(250, min(900, (int) round($remaining['calories'] * ($mealType === 'snack' ? 0.25 : 0.45))));
        $all = Recipe::query()->get();
        $recipes = $all->filter(fn (Recipe $r) => in_array($goal, $r->goal_tags ?? [], true));
        if ($recipes->isEmpty()) {
            $recipes = $all;
        }

        $ranked = $recipes
            ->sortBy(fn (Recipe $r) => [
                $r->meal_type === $mealType ? 0 : 1,
                abs($r->calories - $budget) - ($r->protein * 4), // close to the budget, rich in protein
            ])
            ->take(4);

        return $ranked->map(fn (Recipe $r) => [
            'id' => $r->slug,
            'name' => $r->name,
            'subtitle' => $r->subtitle,
            'mealType' => $r->meal_type,
            'calories' => $r->calories,
            'protein' => $r->protein,
            'carbs' => $r->carbs,
            'fat' => $r->fat,
            'duration' => $r->duration,
            'why' => $r->meal_type === $mealType
                ? 'Idéal pour ton prochain repas · '.$r->protein.' g de protéines'
                : 'Adapté à ton objectif · '.$r->calories.' kcal',
        ])->values()->all();
    }

    private static function pickFoods(string $goal, array $remaining): array
    {
        $query = Food::query();
        if ($remaining['protein'] >= 20) {
            $foods = $query->where('calories', '>', 0)->get()
                ->sortByDesc(fn (Food $f) => $f->protein / max(1, $f->calories))
                ->take(5);
            $why = 'Riche en protéines';
        } elseif ($goal === 'lose_weight' || $remaining['calories'] < 300) {
            $foods = $query->whereIn('category', ['vegetable', 'fruit'])->orderBy('calories')->take(5)->get();
            $why = 'Léger et rassasiant';
        } else {
            $foods = $query->whereIn('category', ['starch', 'legume', 'nuts', 'fruit'])->get()->sortByDesc('calories')->take(5);
            $why = 'Bonne source d’énergie saine';
        }

        return $foods->map(fn (Food $f) => [
            'id' => $f->slug,
            'name' => $f->name,
            'serving' => $f->serving,
            'calories' => $f->calories,
            'protein' => $f->protein,
            'why' => $why,
        ])->values()->all();
    }

    private static function nutritionRules(string $goal, array $targets, array $today, array $remaining, int $mealCount): array
    {
        $goalLabel = mb_strtolower(self::GOAL_LABELS[$goal] ?? $goal);
        $summary = $mealCount === 0
            ? "Objectif {$goalLabel} : vise {$targets['calories']} kcal et {$targets['protein']} g de protéines aujourd'hui. Commence par un repas riche en protéines."
            : "Tu as mangé {$today['calories']} kcal sur {$targets['calories']}. Il te reste {$remaining['calories']} kcal et {$remaining['protein']} g de protéines pour atteindre ton objectif de {$goalLabel}.";

        $tips = match ($goal) {
            'lose_weight' => ['Remplis la moitié de ton assiette de légumes.', 'Privilégie les protéines maigres : poulet, poisson, œufs, skyr.', 'Bois 2 L d’eau, la soif ressemble souvent à la faim.'],
            'gain_muscle', 'clean_bulk' => ['Répartis tes protéines sur 4 repas (25–40 g chacun).', 'Ajoute des glucides complets autour de l’entraînement (riz, avoine, patate douce).', 'Des bons gras (avocat, noix, huile d’olive) pour monter les calories sainement.'],
            'endurance' => ['Glucides complets avant l’effort (avoine, banane, riz).', 'Protéines + glucides dans l’heure qui suit la séance.', 'Hydrate-toi avant, pendant et après le sport.'],
            default => ['Équilibre chaque assiette : protéines, légumes, féculents complets.', 'Limite les produits transformés et sucrés.', 'Garde des collations saines : fruits, yaourt, oléagineux.'],
        };

        if ($remaining['protein'] >= 30) {
            $tips[] = "Il te manque {$remaining['protein']} g de protéines : ajoute une source maigre à ton prochain repas.";
        }
        if ($today['calories'] > $targets['calories']) {
            $tips[] = 'Objectif calorique dépassé : reste léger pour le reste de la journée (légumes, protéines maigres).';
        }

        return ['summary' => $summary, 'tips' => $tips];
    }

    // ───────────────────────────── AI ─────────────────────────────

    /**
     * Asks the LLM for {"summary": "...", "tips": ["..."]}. Cached 3 h per context.
     *
     * @return array{summary: string, tips: array<int, string>}|null
     */
    private static function askAi(string $kind, User $user, array $context, string $system): ?array
    {
        if (! AiClient::enabled()) {
            return null;
        }

        $key = "ai-advice:{$kind}:{$user->id}:".md5(json_encode($context));

        return Cache::remember($key, now()->addHours(3), function () use ($context, $system) {
            $prompt = "Voici les données de l'utilisateur (JSON) :\n".json_encode($context, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT)
                ."\n\nRéponds UNIQUEMENT avec un JSON valide de la forme "
                .'{"summary": "2 à 3 phrases personnalisées", "tips": ["conseil court 1", "conseil court 2", "conseil court 3", "conseil court 4"]}';

            $text = AiClient::chat($system, [['role' => 'user', 'content' => $prompt]], 600, 0.5);
            if (! $text || ! preg_match('/\{.*\}/s', $text, $match)) {
                return null;
            }

            $json = json_decode($match[0], true);
            if (! is_array($json) || ! is_string($json['summary'] ?? null) || ! is_array($json['tips'] ?? null)) {
                return null;
            }

            $tips = array_values(array_filter(array_map(fn ($t) => is_string($t) ? trim($t) : null, $json['tips'])));

            return $tips === [] ? null : ['summary' => trim($json['summary']), 'tips' => array_slice($tips, 0, 6)];
        });
    }
}
