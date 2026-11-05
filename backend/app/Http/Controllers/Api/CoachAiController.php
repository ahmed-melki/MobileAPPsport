<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\AiClient;
use App\Support\ApiResponse;
use App\Support\DailyCoachService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

/**
 * Coach Apex (AI): plan of the day + chat.
 *   GET  /api/me/coach/today?date=YYYY-MM-DD&hour=14
 *   POST /api/me/coach/chat  {message, history: [{role: user|assistant, content}]}
 */
class CoachAiController extends Controller
{
    public function __construct(protected DailyCoachService $coach) {}

    public function today(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'date' => ['nullable', 'date_format:Y-m-d'],
            'hour' => ['nullable', 'integer', 'min:0', 'max:23'],
        ]);

        $plan = $this->coach->today(
            $request->user(),
            $validated['date'] ?? null,
            isset($validated['hour']) ? (int) $validated['hour'] : null,
        );

        return ApiResponse::success($plan, 'Daily plan generated.');
    }

    public function chat(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'message' => ['required', 'string', 'max:1000'],
            'history' => ['nullable', 'array', 'max:20'],
            'history.*.role' => ['required_with:history', 'in:user,assistant'],
            'history.*.content' => ['required_with:history', 'string', 'max:2000'],
            'date' => ['nullable', 'date_format:Y-m-d'],
            'hour' => ['nullable', 'integer', 'min:0', 'max:23'],
        ]);

        $plan = $this->coach->today($request->user(), $validated['date'] ?? null, isset($validated['hour']) ? (int) $validated['hour'] : null);
        $context = DailyCoachService::compactContext($plan);

        $reply = null;
        if (AiClient::enabled()) {
            $system = 'Tu es Coach Apex, coach sportif et nutrition dans une appli tunisienne de salle de sport. '
                .'Réponds en français (ou en derja tunisienne si l’utilisateur l’utilise), tutoiement, réponses courtes (max 120 mots), concrètes, avec des chiffres quand c’est utile. '
                .'Tu connais la cuisine tunisienne (couscous, lablabi, ojja, brik, mloukhia...) et proposes des versions adaptées à l’objectif. '
                .'Base-toi sur le contexte du jour ci-dessous. Hors sport/nutrition/récupération : recentre poliment. '
                .'Jamais de diagnostic médical ni de dosage de médicaments ; en cas de douleur, blessure ou malaise, conseille de consulter un médecin. '
                .'Contexte du jour (JSON) : '.json_encode($context, JSON_UNESCAPED_UNICODE);

            $messages = collect($validated['history'] ?? [])
                ->take(-10)
                ->map(fn ($m) => ['role' => $m['role'], 'content' => $m['content']])
                ->push(['role' => 'user', 'content' => $validated['message']])
                ->values()
                ->all();

            $reply = AiClient::chat($system, $messages, 600, 0.7);
        }

        $source = 'ai';
        if (! $reply) {
            $reply = $this->ruleReply($validated['message'], $plan);
            $source = 'rules';
        }

        return ApiResponse::success([
            'reply' => $reply,
            'source' => $source,
            'aiEnabled' => AiClient::enabled(),
        ]);
    }

    /**
     * Offline answers when no AI key is configured (or the provider fails).
     */
    protected function ruleReply(string $message, array $plan): string
    {
        $m = Str::lower(Str::ascii($message));
        $n = $plan['nutrition'];
        $w = $plan['workout'];

        $has = fn (array $words) => collect($words)->contains(fn ($word) => str_contains($m, $word));

        if ($has(['douleur', 'mal ', 'blesse', 'blessure', 'vertige', 'malaise'])) {
            return 'Si tu as une douleur qui persiste, une blessure ou un malaise, arrête la séance et consulte un médecin ou un kiné. En attendant : repos de la zone, glace 15 min, et on reprend léger quand ça ne fait plus mal.';
        }

        if ($has(['proteine', 'protein'])) {
            return sprintf('Tu es à %d g de protéines sur %d g aujourd’hui. Il te reste %d g : par exemple 1 boîte de thon (26 g), 150 g de skyr (16 g) ou 3 œufs (18 g).',
                (int) $n['consumedProtein'], (int) $n['targetProtein'], (int) $n['remainingProtein']);
        }

        if ($has(['manger', 'repas', 'mange', 'faim', 'diner', 'dejeuner', 'recette', 'snack', 'kol', 'nekel'])) {
            $s = collect($n['suggestions'])->pluck('name')->implode(', ');

            return $s
                ? sprintf('Il te reste %d kcal et %d g de protéines. Pour ton prochain repas je te propose : %s.', $n['remainingCalories'], (int) $n['remainingProtein'], $s)
                : sprintf('Tu as noté tous tes repas. Il te reste %d kcal : un yaourt grec ou un fruit si tu as faim.', $n['remainingCalories']);
        }

        if ($has(['calorie', 'kcal'])) {
            return sprintf('Aujourd’hui : %d kcal consommées sur %d. Il te reste %d kcal.', $n['consumedCalories'], $n['targetCalories'], $n['remainingCalories']);
        }

        if ($has(['seance', 'entrain', 'workout', 'sport', 'exercice', 'muscu', 'training'])) {
            if ($plan['dayType'] === 'training' && $w) {
                $list = collect($w['exercises'])->map(fn ($e) => $e['name'].' '.$e['sets'].'×'.$e['reps'].($e['kind'] === 'load' && $e['loadKg'] > 0 ? ' @ '.$e['loadKg'].' kg' : ''))->implode(', ');

                return sprintf('Aujourd’hui : %s (%d min). Au programme : %s. Échauffe-toi 10 min avant.', $w['title'], $w['durationMin'], $list);
            }
            if ($plan['dayType'] === 'done') {
                return 'Ta séance du jour est déjà faite 💪 Place à la récup : protéines, eau et 7–9 h de sommeil.';
            }
            if ($plan['dayType'] === 'no_program') {
                return sprintf('Tu n’as pas encore de programme actif. Je te conseille « %s ». Lance-le depuis l’onglet Entraînement.', $plan['recommendedProgram']['title'] ?? 'Full Body Débutant');
            }

            return 'Aujourd’hui c’est récupération : 10 min de mobilité et 30 min de marche. Tu reviendras plus fort demain.';
        }

        if ($has(['eau', 'boire', 'hydrat'])) {
            return sprintf('Vise environ %s L d’eau aujourd’hui, réparti sur la journée, et un peu plus autour de la séance.', str_replace('.', ',', (string) $plan['hydration']['targetLiters']));
        }

        if ($has(['poids', 'maigrir', 'secher', 'perdre', 'grossir', 'masse'])) {
            return sprintf('Ton objectif actuel : %s. La clé c’est la régularité : %d séances par semaine, tes protéines chaque jour, et une pesée par semaine le matin à jeun.', $plan['goalLabel'], $plan['weeklyTarget']);
        }

        if ($has(['dormir', 'sommeil', 'fatigue', 'creve'])) {
            return 'La fatigue se gère avec 7–9 h de sommeil, assez de glucides autour des séances et 1 à 2 jours de repos par semaine. Si tu es très fatigué aujourd’hui, fais une séance allégée.';
        }

        return $plan['message'].' Tu peux me demander : « quoi manger ? », « ma séance du jour », « combien de protéines ? »…';
    }
}
