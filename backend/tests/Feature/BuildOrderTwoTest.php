<?php

namespace Tests\Feature;

use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class BuildOrderTwoTest extends TestCase
{
    use RefreshDatabase;

    public function test_training_catalog_and_program_endpoints_work(): void
    {
        $this->seed(DatabaseSeeder::class);

        $user = User::factory()->create([
            'first_name' => 'Lina',
            'last_name' => 'Moreau',
            'email' => 'lina.moreau.training@test.com',
            'role' => 'member',
            'sport_level' => 'advanced',
        ]);

        $this->actingAs($user, 'sanctum');

        $this->getJson('/api/exercises?page=1&category=strength&search=squat')
            ->assertStatus(200)
            ->assertJsonPath('data.0.id', 'squat');

        $this->getJson('/api/training/programs')
            ->assertStatus(200)
            ->assertJsonStructure([
                'data' => [['id', 'title', 'subtitle', 'weeks', 'daysPerWeek', 'level']],
            ]);

        $this->getJson('/api/training/programs/hyrox-engine')
            ->assertStatus(200)
            ->assertJsonPath('data.id', 'hyrox-engine')
            ->assertJsonPath('data.sessions.0.id', 'hyrox-s1');

        $this->getJson('/api/training/sessions/hyrox-s1')
            ->assertStatus(200)
            ->assertJsonPath('data.id', 'hyrox-s1')
            ->assertJsonPath('data.exercises.0.exerciseId', 'squat');
    }

    public function test_user_can_log_training_and_see_progress_and_programs(): void
    {
        $this->seed(DatabaseSeeder::class);

        $user = User::factory()->create(['email' => 'training-user@example.com']);
        $this->actingAs($user, 'sanctum');

        $this->postJson('/api/me/session-logs', [
            'completedAt' => '2026-10-09T18:30:00Z',
            'sessionId' => 'hyrox-s1',
            'sessionTitle' => 'S1 · Lower power',
            'programId' => 'hyrox-engine',
            'programTitle' => 'Hyrox Engine',
            'durationMin' => 64,
            'highlight' => 'Squat + deadlift good day',
            'sets' => [
                ['exerciseId' => 'squat', 'setNumber' => 1, 'reps' => 6, 'loadKg' => 90, 'kind' => 'load'],
                ['exerciseId' => 'deadlift', 'setNumber' => 1, 'reps' => 5, 'loadKg' => 100, 'kind' => 'load'],
            ],
        ])->assertStatus(201)
            ->assertJsonPath('data.sessionTitle', 'S1 · Lower power');

        $this->getJson('/api/me/session-logs')
            ->assertStatus(200)
            ->assertJsonPath('data.0.sessionTitle', 'S1 · Lower power');

        $this->getJson('/api/me/training-progress')
            ->assertStatus(200)
            ->assertJsonPath('data.0.name', 'Squat arrière');

        $this->getJson('/api/me/programs')
            ->assertStatus(200)
            ->assertJsonStructure(['data' => [['program' => ['id']]]]);

        $this->postJson('/api/me/programs/hyrox-engine/start')
            ->assertStatus(200)
            ->assertJsonPath('data.status', 'active');

        $this->postJson('/api/me/programs/hyrox-engine/pause')
            ->assertStatus(200)
            ->assertJsonPath('data.status', 'paused');
    }

    public function test_user_cannot_see_another_users_session_logs(): void
    {
        $this->seed(DatabaseSeeder::class);

        $userA = User::factory()->create(['first_name' => 'Alice', 'email' => 'alice.training@example.com']);
        $userB = User::factory()->create(['first_name' => 'Bob', 'email' => 'bob.training@example.com']);

        $userA->sessionLogs()->create([
            'session_slug' => 'hyrox-s1',
            'program_slug' => 'hyrox-engine',
            'session_title' => 'A session',
            'program_title' => 'Hyrox Engine',
            'date' => '2026-10-01',
            'duration_min' => 60,
            'highlight' => 'Own log',
        ]);

        $userB->sessionLogs()->create([
            'session_slug' => 'hyrox-s2',
            'program_slug' => 'hyrox-engine',
            'session_title' => 'B session',
            'program_title' => 'Hyrox Engine',
            'date' => '2026-10-02',
            'duration_min' => 50,
            'highlight' => 'Other log',
        ]);

        $this->actingAs($userA, 'sanctum');

        $this->getJson('/api/me/session-logs')
            ->assertStatus(200)
            ->assertJsonPath('data.0.sessionTitle', 'A session')
            ->assertJsonMissingPath('data.1.sessionTitle');

        $response = $this->getJson('/api/me/training-progress');
        $response->assertStatus(200);
        $this->assertSame([], $response->json('data'));
    }

    public function test_session_log_validation_errors_are_returned(): void
    {
        $this->seed(DatabaseSeeder::class);

        $user = User::factory()->create(['email' => 'validation-user@example.com']);
        $this->actingAs($user, 'sanctum');

        $this->postJson('/api/me/session-logs', [
            'sessionId' => '',
            'durationMin' => 0,
            'sets' => [[
                'exerciseId' => 'squat',
                'setNumber' => 0,
                'reps' => 0,
                'kind' => 'invalid',
            ]],
        ])->assertStatus(422)
            ->assertJsonValidationErrors(['sessionId', 'durationMin', 'sets.0.setNumber', 'sets.0.reps', 'sets.0.kind']);
    }

    public function test_training_progress_points_are_ordered_by_date_and_load(): void
    {
        $this->seed(DatabaseSeeder::class);

        $user = User::factory()->create(['email' => 'progress-order@example.com']);
        $this->actingAs($user, 'sanctum');

        $payloads = [
            ['completedAt' => '2026-10-01T18:30:00Z', 'sessionId' => 'hyrox-s1', 'programId' => 'hyrox-engine', 'sessionTitle' => 'S1', 'programTitle' => 'Hyrox Engine', 'durationMin' => 60, 'sets' => [['exerciseId' => 'squat', 'setNumber' => 1, 'reps' => 5, 'loadKg' => 80, 'kind' => 'load']]],
            ['completedAt' => '2026-10-02T18:30:00Z', 'sessionId' => 'hyrox-s1', 'programId' => 'hyrox-engine', 'sessionTitle' => 'S1', 'programTitle' => 'Hyrox Engine', 'durationMin' => 60, 'sets' => [['exerciseId' => 'squat', 'setNumber' => 1, 'reps' => 5, 'loadKg' => 85, 'kind' => 'load']]],
            ['completedAt' => '2026-10-03T18:30:00Z', 'sessionId' => 'hyrox-s1', 'programId' => 'hyrox-engine', 'sessionTitle' => 'S1', 'programTitle' => 'Hyrox Engine', 'durationMin' => 60, 'sets' => [['exerciseId' => 'squat', 'setNumber' => 1, 'reps' => 5, 'loadKg' => 90, 'kind' => 'load']]],
            ['completedAt' => '2026-10-04T18:30:00Z', 'sessionId' => 'hyrox-s1', 'programId' => 'hyrox-engine', 'sessionTitle' => 'S1', 'programTitle' => 'Hyrox Engine', 'durationMin' => 60, 'sets' => [['exerciseId' => 'squat', 'setNumber' => 1, 'reps' => 5, 'loadKg' => 95, 'kind' => 'load']]],
        ];

        foreach ($payloads as $payload) {
            $this->postJson('/api/me/session-logs', $payload)->assertStatus(201);
        }

        $this->getJson('/api/me/training-progress')
            ->assertStatus(200)
            ->assertJsonPath('data.0.points.0', 80)
            ->assertJsonPath('data.0.points.1', 85)
            ->assertJsonPath('data.0.points.2', 90)
            ->assertJsonPath('data.0.points.3', 95);
    }

    public function test_session_log_requires_full_iso_completed_at_and_counts_load_volume_only(): void
    {
        $this->seed(DatabaseSeeder::class);

        $user = User::factory()->create(['email' => 'volume-user@example.com']);
        $this->actingAs($user, 'sanctum');

        $this->postJson('/api/me/session-logs', [
            'completedAt' => '2026-10-10',
            'sessionId' => 'hyrox-s1',
            'programId' => 'hyrox-engine',
            'durationMin' => 30,
            'sets' => [['exerciseId' => 'squat', 'setNumber' => 1, 'reps' => 5, 'loadKg' => 80, 'kind' => 'load']],
        ])->assertStatus(422)->assertJsonValidationErrors(['completedAt']);

        $this->postJson('/api/me/session-logs', [
            'completedAt' => '2026-10-10T18:30:00Z',
            'sessionId' => 'hyrox-s1',
            'programId' => 'hyrox-engine',
            'durationMin' => 30,
            'sets' => [
                ['exerciseId' => 'squat', 'setNumber' => 1, 'reps' => 5, 'loadKg' => 80, 'kind' => 'load'],
                ['exerciseId' => 'ski', 'setNumber' => 1, 'reps' => 500, 'loadKg' => 0, 'kind' => 'distance'],
                ['exerciseId' => 'pullup', 'setNumber' => 1, 'reps' => 8, 'loadKg' => 0, 'kind' => 'bodyweight'],
            ],
        ])->assertStatus(201)
            ->assertJsonPath('data.completedAt', '2026-10-10T18:30:00Z')
            ->assertJsonPath('data.volumeKg', 400);
    }

    public function test_seeded_lina_history_drives_dashboard_and_compact_progress(): void
    {
        $this->seed(DatabaseSeeder::class);

        $lina = User::where('email', 'lina.moreau@apex.app')->firstOrFail();
        $this->actingAs($lina, 'sanctum');

        $progressResponse = $this->getJson('/api/me/training-progress')->assertStatus(200);
        $squat = collect($progressResponse->json('data'))->firstWhere('name', 'Squat arrière');
        $this->assertNotNull($squat);
        $this->assertCount(5, $squat['points']);
        $this->assertSame(82.5, $squat['points'][0]);
        $this->assertSame(90, $squat['points'][4]);

        $this->getJson('/api/me/dashboard')
            ->assertStatus(200)
            ->assertJsonPath('data.weeklySessions', 5)
            ->assertJsonPath('data.streakDays', 5);

        $this->getJson('/api/me/session-logs')
            ->assertStatus(200)
            ->assertJsonCount(13, 'data')
            ->assertJsonPath('data.0.completedAt', now()->setTime(18, 30)->utc()->format('Y-m-d\TH:i:s\Z'));
    }
}
