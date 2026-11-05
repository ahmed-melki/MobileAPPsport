<?php

namespace App\Support;

use App\Http\Resources\RecipeResource;
use App\Models\Exercise;
use App\Models\Recipe;
use App\Models\SessionExercise;
use App\Models\TrainingProgram;
use App\Models\User;
use App\Models\UserProgram;
use App\Models\WorkoutSession;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Cache;

/**
 * "Coach Apex" — builds the plan of the day from the user's real data:
 * active program + session logs (what to train, with what load),
 * nutrition targets + meals logged today (what to eat next),
 * readiness/streak (train or recover). The decisions are computed here;
 * the LLM (if configured) only writes the coach message in natural language.
 */
class DailyCoachService
{
    public const GOAL_LABELS = [
        'lose_weight' => 'perte de poids',
        'gain_muscle' => 'prise de muscle',
        'clean_bulk' => 'prise de masse propre',
        'maintain' => 'maintien / forme',
        'endurance' => 'endurance',
    ];

    public function today(User $user, ?string $date = null, ?int $hour = null): array
    {
        $day = $date ? Carbon::parse($date)->startOfDay() : now()->startOfDay();
        $hour ??= (int) now()->format('H');

        $activity = $this->activity($user, $day);
        $training = $this->training($user, $day, $activity);
        $nutrition = $this->nutrition($user, $day, $hour, $training['dayType'] === 'training');
        $weight = $this->latestWeight($user);
        $hydration = round(($weight ?? 70) * 0.035 + ($training['dayType'] === 'training' ? 0.5 : 0), 1);

        $plan = [
            'date' => $day->toDateString(),
            'firstName' => $user->first_name,
            'goal' => $user->main_goal,
            'goalLabel' => self::GOAL_LABELS[$user->main_goal] ?? 'forme générale',
            'readiness' => $activity['readiness'],
            'streakDays' => $activity['streakDays'],
            'weeklySessions' => $activity['weeklySessions'],
            'weeklyTarget' => $activity['weeklyTarget'],
            'dayType' => $training['dayType'],
            'workout' => $training['workout'],
            'recovery' => $training['recovery'],
            'recommendedProgram' => $training['recommendedProgram'],
            'nutrition' => $nutrition,
            'hydration' => ['targetLiters' => $hydration],
            'weightKg' => $weight,
        ];

        $plan['tasks'] = $this->tasks($user, $plan, $activity, $day);
        $rules = $this->ruleMessage($plan);
        $plan['headline'] = $rules['headline'];
        $plan['message'] = $rules['message'];
        $plan['tips'] = $rules['tips'];
        $plan['source'] = 'rules';

        $ai = $this->aiMessage($user, $plan);
        if ($ai) {
            $plan['headline'] = $ai['headline'] ?? $plan['headline'];
            $plan['message'] = $ai['message'] ?? $plan['message'];
            $plan['tips'] = $ai['tips'] ?? $plan['tips'];
            $plan['source'] = 'ai';
        }

        $plan['aiEnabled'] = AiClient::enabled();
        $plan['generatedAt'] = now()->toISOString();

        return $plan;
    }

    // ─── Activity ────────────────────────────────────────────────────

    protected function activity(User $user, Carbon $day): array
    {
        $logs = $user->sessionLogs()->reorder()
            ->whereRaw('COALESCE(completed_at, date) >= ?', [$day->copy()->subDays(28)])
            ->get();

        $dates = $logs->map(fn ($log) => ($log->completed_at ?? $log->date)->toDateString())->unique()->values();
        $weekStart = $day->copy()->subDays(6);
        $weekly = $logs->filter(fn ($log) => ($log->completed_at ?? $log->date)->gte($weekStart))->count();

        $streak = 0;
        $cursor = $dates->contains($day->toDateString()) ? $day->copy() : $day->copy()->subDay();
        while ($dates->contains($cursor->toDateString())) {
            $streak++;
            $cursor->subDay();
        }

        $activeWeeks = $logs->map(fn ($log) => ($log->completed_at ?? $log->date)->format('o-W'))->unique()->count();
        $readiness = (int) round(min($weekly / 5, 1) * 50 + min($activeWeeks / 4, 1) * 30 + min($streak / 7, 1) * 20);

        return [
            'logs' => $logs,
            'dates' => $dates,
            'readiness' => max(0, min(100, $readiness)),
            'streakDays' => $streak,
            'weeklySessions' => $weekly,
            'weeklyTarget' => $user->days_per_week ?: 3,
            'trainedToday' => $dates->contains($day->toDateString()),
            'trainedYesterday' => $dates->contains($day->copy()->subDay()->toDateString()),
            'trainedDayBefore' => $dates->contains($day->copy()->subDays(2)->toDateString()),
        ];
    }

    // ─── Training ────────────────────────────────────────────────────

    protected function training(User $user, Carbon $day, array $activity): array
    {
        $result = ['dayType' => 'training', 'workout' => null, 'recovery' => null, 'recommendedProgram' => null];

        $userProgram = UserProgram::query()
            ->where('user_id', $user->id)
            ->where('status', 'active')
            ->latest('updated_at')
            ->with('program')
            ->first();

        if (! $userProgram || ! $userProgram->program) {
            $top = ProgramRecommender::topFor($user, 1)->first();
            $result['dayType'] = 'no_program';
            $result['recommendedProgram'] = $top ? [
                'id' => $top['program']->slug,
                'title' => $top['program']->title,
                'subtitle' => $top['program']->subtitle,
                'reasons' => $top['reasons'],
            ] : null;
            $result['recovery'] = $this->recoveryBlock($user, 'Commence en douceur');

            return $result;
        }

        /** @var TrainingProgram $program */
        $program = $userProgram->program;
        $sessions = WorkoutSession::query()->where('program_slug', $program->slug)->orderBy('slug')->get();
        $lastLog = $activity['logs']->where('program_slug', $program->slug)
            ->sortByDesc(fn ($log) => ($log->completed_at ?? $log->date)->timestamp)
            ->first()
            ?? $user->sessionLogs()->reorder()->where('program_slug', $program->slug)->orderByRaw('COALESCE(completed_at, date) DESC')->first();

        $nextIndex = 0;
        if ($lastLog) {
            $lastIndex = $sessions->search(fn ($s) => $s->slug === $lastLog->session_slug);
            $nextIndex = $lastIndex === false ? 0 : ($lastIndex + 1) % max(1, $sessions->count());
        }
        $next = $sessions->get($nextIndex);

        if ($activity['trainedToday']) {
            $result['dayType'] = 'done';
            $result['recovery'] = $this->recoveryBlock($user, 'Récupération après ta séance');
        } elseif ($activity['weeklySessions'] >= $activity['weeklyTarget']) {
            $result['dayType'] = 'rest';
            $result['recovery'] = $this->recoveryBlock($user, 'Objectif de la semaine atteint');
        } elseif ($activity['trainedYesterday'] && $activity['trainedDayBefore'] && $activity['weeklyTarget'] <= 4) {
            $result['dayType'] = 'rest';
            $result['recovery'] = $this->recoveryBlock($user, 'Deux jours d’affilée : on récupère');
        }

        if ($next) {
            $result['workout'] = $this->workoutFor($user, $program, $next, $activity['readiness']);
        }

        return $result;
    }

    protected function workoutFor(User $user, TrainingProgram $program, WorkoutSession $session, int $readiness): array
    {
        $light = $readiness < 35;
        $items = SessionExercise::query()->where('session_slug', $session->slug)->orderBy('id')->get();

        $userLevel = LevelAdapter::userLevel($user);
        $programHarder = LevelAdapter::rank($program->level) > LevelAdapter::rank($userLevel);

        $exercises = $items->map(function (SessionExercise $item) use ($user, $light, $userLevel, $programHarder) {
            // 1. Match the exercise to the user's level (easier variant / less volume for beginners).
            $row = LevelAdapter::adapt([
                'exerciseId' => $item->exercise_slug,
                'sets' => (int) $item->sets,
                'reps' => (int) $item->reps,
                'loadKg' => (float) $item->load_kg,
                'restSec' => (int) $item->rest_sec,
                'kind' => $item->kind,
                'unitNote' => $item->unit_note,
            ], $userLevel);

            $plannedLoad = (float) $row['loadKg'];
            $load = $plannedLoad;
            $suggestion = $row['adaptation'];

            // 2. Progressive overload from the user's real history.
            if ($row['kind'] === 'load') {
                $last = ExerciseStats::lastSession($user, $row['exerciseId']);
                if ($last && $last->count() > 0) {
                    $lastLoad = (float) $last->max('load_kg');
                    $avgReps = (float) $last->avg('reps');
                    $step = LevelAdapter::loadStep($userLevel, $row['exerciseId']);

                    if ($lastLoad > 0 && $avgReps >= $row['reps']) {
                        $load = $lastLoad + $step;
                        $suggestion = sprintf('Toutes les reps validées la dernière fois (%s kg) → +%s kg', ExerciseStats::kg($lastLoad), ExerciseStats::kg($step));
                    } elseif ($lastLoad > 0) {
                        $load = $lastLoad;
                        $suggestion = sprintf('Garde %s kg et vise %d reps propres', ExerciseStats::kg($lastLoad), $row['reps']);
                    }
                } else {
                    $suggestion ??= match ($userLevel) {
                        'beginner' => 'Première fois : charge légère, concentre-toi sur la technique.',
                        'advanced' => 'Première fois : monte progressivement jusqu’à RPE 8.',
                        default => 'Première fois : charge de départ, ajuste selon ton ressenti (RPE 7).',
                    };
                    if ($programHarder && $row['adaptedFrom'] === null) {
                        $load = round($plannedLoad * 0.7 / 2.5) * 2.5;
                    }
                }

                if ($light && $load > 0) {
                    $load = round($load * 0.9 / 2.5) * 2.5;
                    $suggestion = 'Readiness basse : séance allégée de 10 %.';
                }
            }

            return [
                'exerciseId' => $row['exerciseId'],
                'name' => Exercise::find($row['exerciseId'])?->name ?? $row['exerciseId'],
                'sets' => $row['sets'],
                'reps' => $row['reps'],
                'loadKg' => round($load, 1),
                'restSec' => $row['restSec'],
                'kind' => $row['kind'],
                'unitNote' => $row['unitNote'],
                'suggestion' => $suggestion,
                'adaptedFrom' => $row['adaptedFrom'],
            ];
        })->values()->all();

        return [
            'sessionId' => $session->slug,
            'programId' => $program->slug,
            'programTitle' => $program->title,
            'title' => $session->title,
            'focus' => $session->focus,
            'durationMin' => (int) $session->duration_min,
            'light' => $light,
            'exercises' => $exercises,
        ];
    }

    protected function recoveryBlock(User $user, string $title): array
    {
        $slugs = ['worlds-greatest-stretch', 'cat-cow', 'hip-90-90', 'thoracic-rotation', 'couch', 'hamstring-stretch'];
        $found = Exercise::query()->whereIn('slug', $slugs)->get()->keyBy('slug');
        $items = collect($slugs)->filter(fn ($s) => $found->has($s))->take(4)->map(fn ($s) => [
            'exerciseId' => $s,
            'name' => $found[$s]->name,
            'detail' => '2 × 45 s',
        ])->values()->all();

        return [
            'title' => $title,
            'items' => $items,
            'walkMinutes' => 30,
        ];
    }

    // ─── Nutrition ───────────────────────────────────────────────────

    protected function nutrition(User $user, Carbon $day, int $hour, bool $trainingDay): array
    {
        $meals = $user->mealEntries()->whereDate('date', $day->toDateString())->get();
        $target = $user->nutritionTarget;
        $targetCalories = $target ? (int) $target->calories : 2200;
        $targetProtein = $target ? (float) $target->protein : 120.0;

        $consumedCalories = (int) $meals->sum('calories');
        $consumedProtein = round((float) $meals->sum('protein'), 1);
        $remainingCalories = max(0, $targetCalories - $consumedCalories);
        $remainingProtein = max(0, round($targetProtein - $consumedProtein, 1));

        $loggedTypes = $meals->pluck('type')->unique()->values()->all();
        $nextMeal = $this->nextMealType($hour, $loggedTypes);

        return [
            'targetCalories' => $targetCalories,
            'consumedCalories' => $consumedCalories,
            'remainingCalories' => $remainingCalories,
            'targetProtein' => $targetProtein,
            'consumedProtein' => $consumedProtein,
            'remainingProtein' => $remainingProtein,
            'mealsLogged' => $meals->count(),
            'loggedTypes' => $loggedTypes,
            'nextMeal' => $nextMeal,
            'suggestions' => $nextMeal ? $this->recipeSuggestions($user, $nextMeal, $remainingCalories, $remainingProtein, $trainingDay) : [],
        ];
    }

    protected function nextMealType(int $hour, array $logged): ?string
    {
        $order = ['breakfast', 'lunch', 'snack', 'dinner'];
        $byHour = match (true) {
            $hour < 10 => 'breakfast',
            $hour < 15 => 'lunch',
            $hour < 18 => 'snack',
            default => 'dinner',
        };

        $start = array_search($byHour, $order, true);
        foreach (array_slice($order, $start) as $type) {
            if (! in_array($type, $logged, true)) {
                return $type;
            }
        }

        return null;
    }

    protected function recipeSuggestions(User $user, string $mealType, int $remainingCalories, float $remainingProtein, bool $trainingDay): array
    {
        $goal = $user->main_goal ?? 'maintain';
        $mealsLeft = match ($mealType) {
            'breakfast' => 4,
            'lunch' => 3,
            'snack' => 2,
            default => 1,
        };
        $budget = $mealsLeft > 0 ? $remainingCalories / $mealsLeft * ($mealType === 'snack' ? 0.6 : 1.2) : $remainingCalories;

        /** @var Collection<int, Recipe> $recipes */
        $recipes = Recipe::query()->get();

        return $recipes
            ->map(function (Recipe $recipe) use ($goal, $mealType, $budget, $remainingProtein, $trainingDay) {
                $score = 0;
                $tags = $recipe->goal_tags ?? [];
                if ($recipe->meal_type === $mealType) {
                    $score += 40;
                } elseif ($recipe->meal_type === null) {
                    $score += 10;
                }
                if (in_array($goal, $tags, true)) {
                    $score += 25;
                }
                $score -= (int) (abs($recipe->calories - $budget) / 25);
                if ($remainingProtein > 40) {
                    $score += (int) ($recipe->protein / max(1, $recipe->calories) * 400);
                }
                if ($trainingDay && in_array($goal, ['gain_muscle', 'clean_bulk', 'endurance'], true)) {
                    $score += (int) (($recipe->carbs ?? 0) / 10);
                }

                return ['recipe' => $recipe, 'score' => $score];
            })
            ->sortByDesc('score')
            ->take(3)
            ->map(function (array $row) use ($remainingProtein) {
                /** @var Recipe $r */
                $r = $row['recipe'];
                $reason = $remainingProtein > 30
                    ? sprintf('%d g de protéines pour combler les %d g restants', (int) $r->protein, (int) $remainingProtein)
                    : sprintf('%d kcal, colle à ton budget du jour', $r->calories);

                return array_merge((new RecipeResource($r))->resolve(), ['reason' => $reason]);
            })
            ->values()
            ->all();
    }

    protected function latestWeight(User $user): ?float
    {
        $m = $user->measurements()->first();

        return $m ? (float) $m->weight_kg : null;
    }

    // ─── Tasks (checklist of the day) ────────────────────────────────

    protected function tasks(User $user, array $plan, array $activity, Carbon $day): array
    {
        $tasks = [];
        $n = $plan['nutrition'];

        if ($plan['dayType'] === 'training' && $plan['workout']) {
            $tasks[] = ['id' => 'workout', 'title' => 'Séance : '.$plan['workout']['title'], 'detail' => $plan['workout']['durationMin'].' min · '.$plan['workout']['focus'], 'icon' => 'bolt', 'done' => false, 'action' => 'workout'];
        } elseif ($plan['dayType'] === 'done') {
            $tasks[] = ['id' => 'workout', 'title' => 'Séance du jour', 'detail' => 'Terminée, bravo', 'icon' => 'bolt', 'done' => true, 'action' => 'workout'];
        } elseif ($plan['dayType'] === 'no_program') {
            $tasks[] = ['id' => 'program', 'title' => 'Choisir un programme', 'detail' => $plan['recommendedProgram']['title'] ?? 'Voir les recommandations', 'icon' => 'bolt', 'done' => false, 'action' => 'program'];
        } else {
            $tasks[] = ['id' => 'recovery', 'title' => 'Mobilité 10 min + marche', 'detail' => $plan['recovery']['walkMinutes'].' min de marche', 'icon' => 'spa', 'done' => false, 'action' => 'recovery'];
        }

        $tasks[] = ['id' => 'protein', 'title' => sprintf('Atteindre %d g de protéines', (int) $n['targetProtein']), 'detail' => sprintf('%d / %d g', (int) $n['consumedProtein'], (int) $n['targetProtein']), 'icon' => 'egg', 'done' => $n['consumedProtein'] >= $n['targetProtein'] * 0.95, 'action' => 'nutrition'];
        $tasks[] = ['id' => 'meals', 'title' => 'Noter tes repas', 'detail' => $n['mealsLogged'].' repas notés', 'icon' => 'restaurant', 'done' => $n['mealsLogged'] >= 3, 'action' => 'nutrition'];
        $tasks[] = ['id' => 'water', 'title' => sprintf('Boire %s L d’eau', str_replace('.', ',', (string) $plan['hydration']['targetLiters'])), 'detail' => 'Réparti sur la journée', 'icon' => 'water', 'done' => false, 'action' => 'water'];

        $lastMeasure = $user->measurements()->first();
        if (! $lastMeasure || Carbon::parse($lastMeasure->measured_at)->lt($day->copy()->subDays(7))) {
            $tasks[] = ['id' => 'weigh', 'title' => 'Te peser', 'detail' => 'Dernière pesée il y a plus de 7 jours', 'icon' => 'scale', 'done' => false, 'action' => 'measure'];
        }

        $tasks[] = ['id' => 'sleep', 'title' => 'Dormir 7 à 9 h', 'detail' => 'La récup fait le progrès', 'icon' => 'bed', 'done' => false, 'action' => 'sleep'];

        return $tasks;
    }

    // ─── Messages ────────────────────────────────────────────────────

    protected function ruleMessage(array $p): array
    {
        $name = $p['firstName'] ?: 'champion';
        $n = $p['nutrition'];
        $tips = [];

        [$headline, $message] = match ($p['dayType']) {
            'training' => [
                'Jour de séance : '.($p['workout']['title'] ?? 'entraînement'),
                sprintf('Salut %s ! Aujourd’hui c’est %s (%d min, %s). %s Vise %d g de protéines et garde %d kcal pour bien récupérer.',
                    $name,
                    $p['workout']['title'] ?? 'ta séance',
                    $p['workout']['durationMin'] ?? 45,
                    mb_strtolower($p['workout']['focus'] ?? 'full body'),
                    ($p['workout']['light'] ?? false) ? 'Ta readiness est basse, on allège un peu les charges.' : 'Les charges sont calculées à partir de ta dernière séance.',
                    (int) $n['targetProtein'],
                    $n['remainingCalories']),
            ],
            'done' => [
                'Séance validée ✔',
                sprintf('Bien joué %s, la séance du jour est faite. Maintenant on récupère : protéines (%d g restants), hydratation et sommeil.', $name, (int) $n['remainingProtein']),
            ],
            'rest' => [
                'Jour de récupération',
                sprintf('%s, ton corps progresse pendant le repos. %d séances cette semaine sur %d prévues : aujourd’hui mobilité légère et marche. Mange normalement, surtout tes protéines.', $name, $p['weeklySessions'], $p['weeklyTarget']),
            ],
            default => [
                'Lance ton programme',
                sprintf('%s, tu n’as pas encore de programme actif. Je te conseille « %s » pour ton objectif %s.', $name, $p['recommendedProgram']['title'] ?? 'un programme débutant', $p['goalLabel']),
            ],
        };

        if ($n['remainingProtein'] > 40) {
            $tips[] = sprintf('Il te manque %d g de protéines : ajoute un skyr, du thon ou des œufs.', (int) $n['remainingProtein']);
        }
        if ($n['mealsLogged'] === 0) {
            $tips[] = 'Note ton premier repas pour que je puisse ajuster tes suggestions.';
        }
        if ($p['streakDays'] >= 3) {
            $tips[] = sprintf('%d jours de suite, belle régularité ! Pense à garder 1 à 2 jours de repos par semaine.', $p['streakDays']);
        }
        if ($p['goal'] === 'lose_weight') {
            $tips[] = 'Pour sécher : des légumes à chaque repas et l’huile d’olive à la cuillère, pas à l’œil.';
        } elseif (in_array($p['goal'], ['gain_muscle', 'clean_bulk'], true)) {
            $tips[] = 'Pour prendre du muscle : un repas riche en glucides 1 à 2 h avant la séance.';
        }
        $tips[] = sprintf('Bois environ %s L d’eau aujourd’hui.', str_replace('.', ',', (string) $p['hydration']['targetLiters']));

        return ['headline' => $headline, 'message' => $message, 'tips' => array_slice($tips, 0, 3)];
    }

    protected function aiMessage(User $user, array $plan): ?array
    {
        if (! AiClient::enabled()) {
            return null;
        }

        $context = self::compactContext($plan);
        $key = 'coach:today:'.$user->id.':'.md5(json_encode($context));

        return Cache::remember($key, now()->addHours(6), function () use ($context) {
            $system = 'Tu es Coach Apex, coach sportif et nutrition dans une appli tunisienne. '
                .'Tu parles en français, tutoiement, ton motivant et concret, phrases courtes. '
                .'Tu NE modifies PAS le plan (séance, charges, recettes) : tu l’expliques et motives. '
                .'Pas de diagnostic médical. Réponds UNIQUEMENT en JSON valide : '
                .'{"headline": "max 8 mots", "message": "max 70 mots", "tips": ["3 conseils de max 18 mots"]}';

            $text = AiClient::chat($system, [[
                'role' => 'user',
                'content' => 'Plan du jour de l’utilisateur (JSON) : '.json_encode($context, JSON_UNESCAPED_UNICODE),
            ]], 500, 0.7);

            if (! $text) {
                return null;
            }

            $json = trim(preg_replace('/^```(json)?|```$/m', '', $text));
            $data = json_decode($json, true);
            if (! is_array($data) || empty($data['message'])) {
                return null;
            }

            return [
                'headline' => isset($data['headline']) ? mb_substr((string) $data['headline'], 0, 80) : null,
                'message' => mb_substr((string) $data['message'], 0, 600),
                'tips' => isset($data['tips']) && is_array($data['tips']) ? array_slice(array_map('strval', $data['tips']), 0, 3) : null,
            ];
        });
    }

    /**
     * Small context (no personal identifiers besides first name) sent to the LLM.
     */
    public static function compactContext(array $plan): array
    {
        return [
            'prenom' => $plan['firstName'],
            'objectif' => $plan['goalLabel'],
            'readiness' => $plan['readiness'],
            'streak' => $plan['streakDays'],
            'seances_semaine' => $plan['weeklySessions'].'/'.$plan['weeklyTarget'],
            'type_de_jour' => $plan['dayType'],
            'seance' => $plan['workout'] ? [
                'titre' => $plan['workout']['title'],
                'focus' => $plan['workout']['focus'],
                'duree_min' => $plan['workout']['durationMin'],
                'exercices' => array_map(fn ($e) => $e['name'].' '.$e['sets'].'x'.$e['reps'].($e['kind'] === 'load' ? ' @'.$e['loadKg'].'kg' : ''), $plan['workout']['exercises']),
            ] : null,
            'programme_conseille' => $plan['recommendedProgram']['title'] ?? null,
            'nutrition' => [
                'kcal' => $plan['nutrition']['consumedCalories'].'/'.$plan['nutrition']['targetCalories'],
                'proteines_g' => $plan['nutrition']['consumedProtein'].'/'.$plan['nutrition']['targetProtein'],
                'prochain_repas' => $plan['nutrition']['nextMeal'],
                'suggestions' => array_map(fn ($r) => $r['name'], $plan['nutrition']['suggestions']),
            ],
            'eau_litres' => $plan['hydration']['targetLiters'],
            'poids_kg' => $plan['weightKg'],
        ];
    }
}
