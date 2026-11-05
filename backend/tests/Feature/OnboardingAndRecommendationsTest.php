<?php

namespace Tests\Feature;

use App\Models\BodyMeasurement;
use App\Models\Goal;
use App\Models\TrainingProgram;
use App\Models\User;
use App\Support\NutritionCalculator;
use App\Support\OnboardingService;
use App\Support\TrainingCatalog;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class OnboardingAndRecommendationsTest extends TestCase
{
    use RefreshDatabase;

    public function test_seeded_lina_has_completed_onboarding(): void
    {
        $this->seed(DatabaseSeeder::class);

        $lina = User::query()->where('email', 'lina.moreau@apex.app')->firstOrFail();
        $this->actingAs($lina, 'sanctum');

        $this->getJson('/api/me')
            ->assertOk()
            ->assertJsonPath('data.onboardingCompleted', true)
            ->assertJsonPath('data.sex', 'female')
            ->assertJsonPath('data.mainGoal', 'endurance')
            ->assertJsonPath('data.experienceLevel', 'expert')
            ->assertJsonPath('data.level', 'advanced')
            ->assertJsonPath('data.daysPerWeek', 5)
            ->assertJsonPath('data.equipment', 'gym');
    }

    public function test_onboarding_validation_rejects_invalid_payloads(): void
    {
        $user = User::factory()->create();
        $this->actingAs($user, 'sanctum');

        $this->postJson('/api/me/onboarding', [])
            ->assertStatus(422)
            ->assertJsonStructure(['message', 'errors']);

        $this->postJson('/api/me/onboarding', $this->validPayload([
            'age' => 10,
            'heightCm' => 100,
            'weightKg' => 20,
            'mainGoal' => 'bulk',
            'experienceLevel' => 'pro',
            'daysPerWeek' => 1,
            'equipment' => 'bands',
            'sex' => 'unknown',
        ]))->assertStatus(422);
    }

    public function test_onboarding_creates_goal_measurement_targets_and_profile(): void
    {
        TrainingCatalog::ensureSeeded();

        $user = User::factory()->create([
            'sport_level' => 'beginner',
            'onboarding_completed_at' => null,
        ]);
        $this->actingAs($user, 'sanctum');

        $payload = $this->validPayload();
        $expectedTargets = NutritionCalculator::compute(
            $payload['sex'],
            $payload['age'],
            $payload['heightCm'],
            $payload['weightKg'],
            $payload['daysPerWeek'],
            $payload['mainGoal'],
        );

        $response = $this->postJson('/api/me/onboarding', $payload)
            ->assertOk()
            ->assertJsonPath('data.profile.onboardingCompleted', true)
            ->assertJsonPath('data.profile.sex', 'female')
            ->assertJsonPath('data.profile.mainGoal', 'lose_weight')
            ->assertJsonPath('data.profile.experienceLevel', 'beginner')
            ->assertJsonPath('data.profile.level', 'beginner')
            ->assertJsonPath('data.profile.daysPerWeek', 3)
            ->assertJsonPath('data.profile.equipment', 'gym')
            ->assertJsonPath('data.recommendations.0.id', 'beginner-fat-loss');

        $this->assertCount(3, $response->json('data.recommendations'));

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'sex' => 'female',
            'main_goal' => 'lose_weight',
            'experience_level' => 'beginner',
            'sport_level' => 'beginner',
            'days_per_week' => 3,
            'equipment' => 'gym',
        ]);
        $this->assertNotNull($user->fresh()->onboarding_completed_at);

        $this->assertDatabaseHas('body_measurements', [
            'user_id' => $user->id,
            'measured_at' => now()->toDateString(),
            'weight_kg' => 70,
        ]);

        $this->assertDatabaseHas('goals', [
            'user_id' => $user->id,
            'kind' => 'weight_loss',
            'is_primary' => 1,
            'is_active' => 1,
        ]);

        $this->assertDatabaseHas('nutrition_targets', [
            'user_id' => $user->id,
            'calories' => $expectedTargets['calories'],
            'protein' => $expectedTargets['protein'],
            'carbs' => $expectedTargets['carbs'],
            'fat' => $expectedTargets['fat'],
        ]);

        $this->getJson('/api/me')
            ->assertOk()
            ->assertJsonPath('data.onboardingCompleted', true)
            ->assertJsonPath('data.level', 'beginner');
    }

    public function test_onboarding_maps_expert_experience_to_advanced_sport_level(): void
    {
        TrainingCatalog::ensureSeeded();

        $user = User::factory()->create(['sport_level' => 'beginner']);
        $this->actingAs($user, 'sanctum');

        $this->postJson('/api/me/onboarding', $this->validPayload([
            'experienceLevel' => 'expert',
            'mainGoal' => 'gain_muscle',
            'daysPerWeek' => 4,
        ]))->assertOk()
            ->assertJsonPath('data.profile.experienceLevel', 'expert')
            ->assertJsonPath('data.profile.level', 'advanced');

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'experience_level' => 'expert',
            'sport_level' => 'advanced',
        ]);
    }

    public function test_recommendations_differ_for_beginner_fat_loss_and_expert_gain_muscle(): void
    {
        TrainingCatalog::ensureSeeded();
        $this->assertGreaterThanOrEqual(6, TrainingProgram::query()->count());

        $beginner = User::factory()->create();
        $this->actingAs($beginner, 'sanctum');
        $this->postJson('/api/me/onboarding', $this->validPayload([
            'mainGoal' => 'lose_weight',
            'experienceLevel' => 'beginner',
            'daysPerWeek' => 3,
        ]))->assertOk();

        $beginnerRecos = $this->getJson('/api/me/recommendations')
            ->assertOk()
            ->assertJsonPath('data.0.id', 'beginner-fat-loss')
            ->assertJsonPath('data.0.reasons.0', 'Adapté aux débutants');

        $this->assertCount(3, $beginnerRecos->json('data'));
        $this->assertContains('Correspond à ton objectif : perte de poids', $beginnerRecos->json('data.0.reasons'));
        $this->assertContains('3 séances par semaine comme tu le souhaites', $beginnerRecos->json('data.0.reasons'));

        $expert = User::factory()->create();
        $this->actingAs($expert, 'sanctum');
        $this->postJson('/api/me/onboarding', $this->validPayload([
            'sex' => 'male',
            'age' => 32,
            'heightCm' => 182,
            'weightKg' => 82,
            'mainGoal' => 'gain_muscle',
            'experienceLevel' => 'expert',
            'daysPerWeek' => 4,
            'equipment' => 'gym',
        ]))->assertOk();

        $expertRecos = $this->getJson('/api/me/recommendations')
            ->assertOk()
            ->assertJsonPath('data.0.id', 'advanced-strength');

        $this->assertCount(3, $expertRecos->json('data'));
        // Never a beginner program for an expert
        foreach ($expertRecos->json('data') as $reco) {
            $this->assertNotSame('beginner', $reco['level'] ?? null);
        }
        $this->assertContains('Adapté au niveau avancé', $expertRecos->json('data.0.reasons'));
        $this->assertContains('Correspond à ton objectif : prise de masse', $expertRecos->json('data.0.reasons'));
        $this->assertNotSame(
            $beginnerRecos->json('data.0.id'),
            $expertRecos->json('data.0.id'),
        );

        $this->postJson('/api/me/programs/hyrox-engine/start')
            ->assertOk()
            ->assertJsonPath('data.status', 'active')
            ->assertJsonPath('data.program.id', 'hyrox-engine');
    }

    public function test_nutrition_targets_use_mifflin_st_jeor_and_goal_adjustments(): void
    {
        TrainingCatalog::ensureSeeded();

        $user = User::factory()->create();
        $this->actingAs($user, 'sanctum');

        $payload = $this->validPayload([
            'sex' => 'female',
            'age' => 30,
            'heightCm' => 165,
            'weightKg' => 70,
            'daysPerWeek' => 3,
            'mainGoal' => 'lose_weight',
            'experienceLevel' => 'beginner',
        ]);

        $this->postJson('/api/me/onboarding', $payload)->assertOk();

        $bmr = (10 * 70) + (6.25 * 165) - (5 * 30) - 161;
        $tdee = $bmr * 1.55;
        $calories = (int) round($tdee - 400);
        $protein = round(70 * 2.2, 1);
        $fat = round($calories * 0.25 / 9, 1);
        $carbs = round(max(0, $calories - ($protein * 4) - ($fat * 9)) / 4, 1);

        $targets = $this->getJson('/api/me/nutrition-targets')
            ->assertOk()
            ->json('data');

        $this->assertSame($calories, $targets['calories']);
        $this->assertEquals($protein, $targets['protein']);
        $this->assertEquals($carbs, $targets['carbs']);
        $this->assertEquals($fat, $targets['fat']);
    }

    public function test_unauthenticated_requests_are_rejected(): void
    {
        $this->postJson('/api/me/onboarding', $this->validPayload())
            ->assertUnauthorized();

        $this->getJson('/api/me/recommendations')
            ->assertUnauthorized();
    }

    public function test_clean_bulk_and_gain_muscle_nutrition_calculations(): void
    {
        TrainingCatalog::ensureSeeded();

        $user = User::factory()->create();
        $this->actingAs($user, 'sanctum');

        // clean_bulk: +10% calories, 2.0 g/kg protein
        $this->postJson('/api/me/onboarding', $this->validPayload([
            'sex' => 'male',
            'age' => 25,
            'heightCm' => 180,
            'weightKg' => 80,
            'daysPerWeek' => 4,
            'mainGoal' => 'clean_bulk',
            'experienceLevel' => 'intermediate',
        ]))->assertOk();

        $bmrClean = (10 * 80) + (6.25 * 180) - (5 * 25) + 5; // 1805
        $tdeeClean = $bmrClean * 1.65; // 2978.25
        $expectedCleanKcal = (int) round($tdeeClean * 1.10); // 3276
        $expectedCleanProtein = round(80 * 2.0, 1); // 160.0

        $cleanTargets = $this->getJson('/api/me/nutrition-targets')->assertOk()->json('data');
        $this->assertSame($expectedCleanKcal, $cleanTargets['calories']);
        $this->assertEquals($expectedCleanProtein, $cleanTargets['protein']);

        // gain_muscle: +300 calories, 2.2 g/kg protein, sex 'other' uses average of male (+5) and female (-161) = -78
        $this->postJson('/api/me/onboarding', $this->validPayload([
            'sex' => 'other',
            'age' => 26,
            'heightCm' => 175,
            'weightKg' => 75,
            'daysPerWeek' => 5,
            'mainGoal' => 'gain_muscle',
            'experienceLevel' => 'expert',
        ]))->assertOk();

        $bmrMuscle = (10 * 75) + (6.25 * 175) - (5 * 26) - 78; // 1635.75
        $tdeeMuscle = $bmrMuscle * 1.725; // 2821.66875
        $expectedMuscleKcal = (int) round($tdeeMuscle + 300); // 3122
        $expectedMuscleProtein = round(75 * 2.2, 1); // 165.0

        $muscleTargets = $this->getJson('/api/me/nutrition-targets')->assertOk()->json('data');
        $this->assertSame($expectedMuscleKcal, $muscleTargets['calories']);
        $this->assertEquals($expectedMuscleProtein, $muscleTargets['protein']);
    }

    public function test_repeated_onboarding_updates_measurement_and_unsets_previous_primary_goal(): void
    {
        TrainingCatalog::ensureSeeded();

        $user = User::factory()->create();
        $this->actingAs($user, 'sanctum');

        // First onboarding
        $this->postJson('/api/me/onboarding', $this->validPayload([
            'weightKg' => 70,
            'mainGoal' => 'lose_weight',
        ]))->assertOk();

        $this->assertSame(1, BodyMeasurement::query()->where('user_id', $user->id)->count());
        $this->assertSame(70.0, (float) BodyMeasurement::query()->where('user_id', $user->id)->first()->weight_kg);
        $this->assertSame(1, Goal::query()->where('user_id', $user->id)->where('is_primary', true)->count());

        // Re-run onboarding same day
        $this->postJson('/api/me/onboarding', $this->validPayload([
            'weightKg' => 72,
            'mainGoal' => 'gain_muscle',
        ]))->assertOk();

        // Measurement must be updated, not duplicated
        $this->assertSame(1, BodyMeasurement::query()->where('user_id', $user->id)->count());
        $this->assertSame(72.0, (float) BodyMeasurement::query()->where('user_id', $user->id)->first()->weight_kg);

        // Previous primary goal must be unset, only one primary goal remains
        $this->assertSame(1, Goal::query()->where('user_id', $user->id)->where('is_primary', true)->count());
        $primaryGoal = Goal::query()->where('user_id', $user->id)->where('is_primary', true)->first();
        $this->assertSame('mass_gain', $primaryGoal->kind);
        $this->assertSame(2, Goal::query()->where('user_id', $user->id)->count());
    }

    public function test_recommendations_rank_home_and_none_programs_first_for_home_and_none_users(): void
    {
        TrainingCatalog::ensureSeeded();

        // User with home equipment
        $homeUser = User::factory()->create();
        $this->actingAs($homeUser, 'sanctum');
        $this->postJson('/api/me/onboarding', $this->validPayload([
            'equipment' => 'home',
            'experienceLevel' => 'beginner',
            'daysPerWeek' => 3,
            'mainGoal' => 'maintain',
        ]))->assertOk();

        $homeRecos = $this->getJson('/api/me/recommendations')->assertOk()->json('data');
        $this->assertCount(3, $homeRecos);
        $this->assertSame('beginner-home-bodyweight', $homeRecos[0]['id']);

        // User with none equipment
        $noneUser = User::factory()->create();
        $this->actingAs($noneUser, 'sanctum');
        $this->postJson('/api/me/onboarding', $this->validPayload([
            'equipment' => 'none',
            'experienceLevel' => 'beginner',
            'daysPerWeek' => 3,
            'mainGoal' => 'lose_weight',
        ]))->assertOk();

        $noneRecos = $this->getJson('/api/me/recommendations')->assertOk()->json('data');
        $this->assertCount(3, $noneRecos);
        $this->assertSame('beginner-home-bodyweight', $noneRecos[0]['id']);
        $this->assertContains('Faisable sans matériel (poids du corps)', $noneRecos[0]['reasons']);
    }

    public function test_onboarding_transaction_rolls_back_on_failure(): void
    {
        $user = User::factory()->create([
            'height_cm' => 170,
            'onboarding_completed_at' => null,
        ]);
        $this->actingAs($user, 'sanctum');

        $failingService = new class extends OnboardingService {
            public function complete(User $user, array $payload): User
            {
                \Illuminate\Support\Facades\DB::transaction(function () use ($user, $payload) {
                    $user->update(['height_cm' => 199]);
                    $user->measurements()->create([
                        'measured_at' => now()->toDateString(),
                        'weight_kg' => 99,
                    ]);

                    throw new \RuntimeException('Simulated transactional failure');
                });

                return $user;
            }
        };

        $this->app->instance(OnboardingService::class, $failingService);

        try {
            $this->postJson('/api/me/onboarding', $this->validPayload());
        } catch (\RuntimeException $e) {
            // caught simulated exception
        }

        $this->assertDatabaseMissing('body_measurements', ['weight_kg' => 99]);
        $this->assertDatabaseMissing('users', ['id' => $user->id, 'height_cm' => 199]);
        $this->assertSame(170, $user->fresh()->height_cm);
        $this->assertNull($user->fresh()->onboarding_completed_at);
    }

    public function test_profile_update_syncs_sport_level_and_experience_level_in_both_directions(): void
    {
        $user = User::factory()->create([
            'sport_level' => 'beginner',
            'experience_level' => 'beginner',
        ]);
        $this->actingAs($user, 'sanctum');

        // PUT with level: advanced -> experienceLevel becomes expert
        $this->putJson('/api/me', [
            'level' => 'advanced',
        ])->assertOk()
            ->assertJsonPath('data.level', 'advanced')
            ->assertJsonPath('data.experienceLevel', 'expert');

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'sport_level' => 'advanced',
            'experience_level' => 'expert',
        ]);

        // PUT with experienceLevel: intermediate -> level becomes intermediate
        $this->putJson('/api/me', [
            'experienceLevel' => 'intermediate',
        ])->assertOk()
            ->assertJsonPath('data.level', 'intermediate')
            ->assertJsonPath('data.experienceLevel', 'intermediate');

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'sport_level' => 'intermediate',
            'experience_level' => 'intermediate',
        ]);
    }

    /**
     * @param  array<string, mixed>  $overrides
     * @return array<string, mixed>
     */
    private function validPayload(array $overrides = []): array
    {
        return array_merge([
            'sex' => 'female',
            'age' => 28,
            'heightCm' => 168,
            'weightKg' => 70,
            'mainGoal' => 'lose_weight',
            'experienceLevel' => 'beginner',
            'daysPerWeek' => 3,
            'equipment' => 'gym',
        ], $overrides);
    }
}
