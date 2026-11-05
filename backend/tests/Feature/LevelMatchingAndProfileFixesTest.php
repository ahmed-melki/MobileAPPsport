<?php

namespace Tests\Feature;

use App\Models\Exercise;
use App\Models\SessionExercise;
use App\Models\TrainingProgram;
use App\Models\User;
use App\Support\TrainingCatalog;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class LevelMatchingAndProfileFixesTest extends TestCase
{
    use RefreshDatabase;

    public function test_every_level_has_programs_and_beginner_programs_only_use_beginner_exercises(): void
    {
        TrainingCatalog::ensureSeeded();

        foreach (['beginner', 'intermediate', 'advanced'] as $level) {
            $this->assertGreaterThanOrEqual(3, TrainingProgram::where('level', $level)->count(), $level);
        }

        $beginnerSessions = TrainingProgram::where('level', 'beginner')->with('sessions')->get()->flatMap->sessions->pluck('slug');
        $levels = SessionExercise::whereIn('session_slug', $beginnerSessions)->pluck('exercise_slug')
            ->map(fn ($slug) => Exercise::find($slug)->level)->unique()->values()->all();

        $this->assertSame(['beginner'], $levels);

        // Advanced programs contain expert / technical lifts
        $advancedSessions = TrainingProgram::where('level', 'advanced')->with('sessions')->get()->flatMap->sessions->pluck('slug');
        $this->assertTrue(SessionExercise::whereIn('session_slug', $advancedSessions)->where('exercise_slug', 'pclean')->exists());
    }

    public function test_beginner_gets_easier_variants_when_opening_an_advanced_session(): void
    {
        TrainingCatalog::ensureSeeded();
        $beginner = User::factory()->create(['sport_level' => 'beginner', 'experience_level' => 'beginner']);
        $this->actingAs($beginner, 'sanctum');

        $exercises = $this->getJson('/api/training/sessions/as-a')->assertOk()->json('data.exercises');
        $this->assertSame('goblet-squat', $exercises[0]['exerciseId']);
        $this->assertSame('squat', $exercises[0]['adaptedFrom']);
        $this->assertLessThanOrEqual(3, $exercises[0]['sets']);
        $this->assertSame('lat-pulldown', $exercises[2]['exerciseId']);

        $advanced = User::factory()->create(['sport_level' => 'advanced', 'experience_level' => 'expert']);
        $this->actingAs($advanced, 'sanctum');
        $exercises = $this->getJson('/api/training/sessions/as-a')->assertOk()->json('data.exercises');
        $this->assertSame('squat', $exercises[0]['exerciseId']);
        $this->assertSame(5, $exercises[0]['sets']);
        $this->assertNull($exercises[0]['adaptedFrom']);
    }

    public function test_recommendations_never_skip_two_levels(): void
    {
        TrainingCatalog::ensureSeeded();
        $user = User::factory()->create();
        $this->actingAs($user, 'sanctum');
        $this->postJson('/api/me/onboarding', [
            'sex' => 'female', 'age' => 25, 'heightCm' => 165, 'weightKg' => 60,
            'mainGoal' => 'gain_muscle', 'experienceLevel' => 'beginner', 'daysPerWeek' => 4, 'equipment' => 'gym',
        ])->assertOk();

        $ids = collect($this->getJson('/api/me/recommendations')->json('data'))->pluck('id');
        $levels = TrainingProgram::whereIn('slug', $ids)->pluck('level')->unique()->values()->all();
        $this->assertNotContains('advanced', $levels);
        $this->assertSame('beginner', TrainingProgram::find($ids[0])->level);
    }

    public function test_level_change_is_saved_even_when_experience_level_is_sent(): void
    {
        $this->seed(DatabaseSeeder::class);
        $admin = User::where('email', 'admin@apex.app')->firstOrFail();
        $this->actingAs($admin, 'sanctum');

        // The app sends both "level" and the old "experienceLevel"
        $this->putJson('/api/me', ['level' => 'beginner', 'experienceLevel' => 'expert'])
            ->assertOk()
            ->assertJsonPath('data.level', 'beginner')
            ->assertJsonPath('data.experienceLevel', 'beginner');

        $this->putJson('/api/me', ['level' => 'intermediate'])->assertOk()->assertJsonPath('data.level', 'intermediate');
        $this->getJson('/api/me')->assertJsonPath('data.level', 'intermediate');
    }

    public function test_measurement_same_day_updates_and_mensurations_are_optional(): void
    {
        $this->seed(DatabaseSeeder::class);
        $admin = User::where('email', 'admin@apex.app')->firstOrFail();
        $this->actingAs($admin, 'sanctum');
        $today = now()->toDateString();

        $this->postJson('/api/me/measurements', ['date' => $today, 'weightKg' => 80])->assertCreated();
        $this->postJson('/api/me/measurements', ['date' => $today, 'weightKg' => 79.5, 'waistCm' => 84])->assertCreated();

        $list = $this->getJson('/api/me/measurements')->assertOk()->json('data');
        $this->assertCount(1, $list);
        $this->assertEquals(79.5, $list[0]['weightKg']);
        $this->assertEquals(84, $list[0]['waistCm']);
        $this->assertNull($list[0]['chestCm']);
    }
}
