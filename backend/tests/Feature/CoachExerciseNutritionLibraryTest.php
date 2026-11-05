<?php

namespace Tests\Feature;

use App\Models\User;
use App\Support\ExerciseLibrary;
use App\Support\NutritionLibrary;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class CoachExerciseNutritionLibraryTest extends TestCase
{
    use RefreshDatabase;

    protected function lina(): User
    {
        $this->seed(DatabaseSeeder::class);

        return User::where('email', 'lina.moreau@apex.app')->firstOrFail();
    }

    public function test_library_seeds_many_exercises_foods_and_recipes(): void
    {
        $this->seed(DatabaseSeeder::class);

        $this->assertGreaterThanOrEqual(60, \App\Models\Exercise::count());
        $this->assertGreaterThanOrEqual(90, \App\Models\Food::count());
        $this->assertGreaterThanOrEqual(30, \App\Models\Recipe::count());
        $this->assertSame(count(ExerciseLibrary::rows()), ExerciseLibrary::seed()); // idempotent
        NutritionLibrary::seed();
        $this->assertSame(count(NutritionLibrary::foods()), \App\Models\Food::count());
        $this->assertNull(\App\Models\Food::find('ojja'));
        $this->assertNull(\App\Models\Recipe::find('ojja-fit'));
    }

    public function test_exercises_are_not_paginated_and_can_be_filtered_by_muscle_and_home(): void
    {
        $this->actingAs($this->lina(), 'sanctum');

        $all = $this->getJson('/api/exercises')->assertOk()->json('data');
        $this->assertGreaterThan(20, count($all));

        $chest = $this->getJson('/api/exercises?muscleGroup=chest')->assertOk()->json('data');
        $this->assertNotEmpty($chest);
        foreach ($chest as $exercise) {
            $this->assertSame('chest', $exercise['muscleGroup']);
        }

        $home = $this->getJson('/api/exercises?atHome=1')->assertOk()->json('data');
        foreach ($home as $exercise) {
            $this->assertTrue($exercise['atHome']);
        }

        $this->getJson('/api/exercises?search=squat')->assertOk()->assertJsonPath('data.0.id', 'squat');
    }

    public function test_exercise_last_perf_and_history_come_from_real_logs(): void
    {
        $user = $this->lina();
        $this->actingAs($user, 'sanctum');

        $this->postJson('/api/me/session-logs', [
            'sessionId' => 'f5-a',
            'programId' => 'five-five',
            'completedAt' => now()->utc()->format('Y-m-d\TH:i:s\Z'),
            'durationMin' => 40,
            'sets' => [
                ['exerciseId' => 'bench', 'setNumber' => 1, 'reps' => 5, 'loadKg' => 57.5, 'kind' => 'load'],
                ['exerciseId' => 'bench', 'setNumber' => 2, 'reps' => 5, 'loadKg' => 57.5, 'kind' => 'load'],
            ],
        ])->assertCreated();

        $bench = collect($this->getJson('/api/exercises')->json('data'))->firstWhere('id', 'bench');
        $this->assertSame('2 × 5 @ 57,5 kg', $bench['lastPerf']);

        $this->getJson('/api/exercises/bench')
            ->assertOk()
            ->assertJsonPath('data.exercise.id', 'bench')
            ->assertJsonPath('data.history.personalBest.loadKg', 57.5)
            ->assertJsonPath('data.history.sessions.0.summary', '2 × 5 @ 57,5 kg');

        $this->getJson('/api/exercises/does-not-exist')->assertNotFound();
    }

    public function test_coach_today_returns_a_full_plan_without_ai_key(): void
    {
        config(['services.ai.key' => null]);
        $this->actingAs($this->lina(), 'sanctum');

        $response = $this->getJson('/api/me/coach/today?hour=12&date='.now()->toDateString())->assertOk();

        $response->assertJsonPath('data.source', 'rules')
            ->assertJsonPath('data.aiEnabled', false)
            ->assertJsonStructure(['data' => [
                'date', 'headline', 'message', 'tips', 'dayType', 'readiness',
                'nutrition' => ['targetCalories', 'consumedCalories', 'remainingCalories', 'remainingProtein', 'nextMeal', 'suggestions'],
                'hydration' => ['targetLiters'],
                'tasks' => [['id', 'title', 'done', 'action']],
            ]]);

        $this->assertContains($response->json('data.dayType'), ['training', 'rest', 'done', 'no_program']);
        // Lina has an active Hyrox program, so there is always a next session
        $this->assertNotNull($response->json('data.workout.sessionId'));
        $this->assertNotEmpty($response->json('data.workout.exercises'));
    }

    public function test_coach_today_without_program_recommends_one(): void
    {
        $this->seed(DatabaseSeeder::class);
        $user = User::factory()->create(['main_goal' => 'lose_weight', 'experience_level' => 'beginner', 'days_per_week' => 3, 'equipment' => 'gym']);
        $this->actingAs($user, 'sanctum');

        $this->getJson('/api/me/coach/today')
            ->assertOk()
            ->assertJsonPath('data.dayType', 'no_program')
            ->assertJsonPath('data.tasks.0.action', 'program');
    }

    public function test_coach_chat_falls_back_to_rules_and_uses_ai_when_configured(): void
    {
        config(['services.ai.key' => null]);
        $this->actingAs($this->lina(), 'sanctum');

        $reply = $this->postJson('/api/me/coach/chat', ['message' => 'Combien de protéines il me reste ?'])
            ->assertOk()
            ->assertJsonPath('data.source', 'rules')
            ->json('data.reply');
        $this->assertStringContainsString('protéines', $reply);

        config(['services.ai.key' => 'test-key', 'services.ai.provider' => 'gemini']);
        Http::fake([
            'generativelanguage.googleapis.com/*' => Http::response([
                'candidates' => [['content' => ['parts' => [['text' => 'Mange un bol de lablabi protéiné 💪']]]]],
            ]),
        ]);

        $this->postJson('/api/me/coach/chat', ['message' => 'Quoi manger ce soir ?', 'history' => [['role' => 'assistant', 'content' => 'Salut !']]])
            ->assertOk()
            ->assertJsonPath('data.source', 'ai')
            ->assertJsonPath('data.reply', 'Mange un bol de lablabi protéiné 💪');
    }

    public function test_nutrition_week_and_recipes_expose_macros(): void
    {
        $this->actingAs($this->lina(), 'sanctum');

        $week = $this->getJson('/api/me/nutrition/week')->assertOk()->json('data');
        $this->assertCount(7, $week['days']);
        $this->assertSame(2350, $week['targetCalories']);

        $recipe = collect($this->getJson('/api/nutrition/recipes')->json('data'))->firstWhere('id', 'salade-tunisienne-thon');
        $this->assertNotNull($recipe);
        $this->assertTrue($recipe['isTunisian']);
        $this->assertGreaterThan(0, $recipe['carbs']);
        $this->assertNotEmpty($recipe['steps']);

        $tn = $this->getJson('/api/nutrition/foods?tunisian=1')->assertOk()->json('data');
        $this->assertNotEmpty($tn);
        foreach ($tn as $food) {
            $this->assertTrue($food['isTunisian']);
        }
    }
}
