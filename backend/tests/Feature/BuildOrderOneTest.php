<?php

namespace Tests\Feature;

use App\Models\Goal;
use App\Models\BodyMeasurement;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class BuildOrderOneTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_register_and_login(): void
    {
        $payload = [
            'firstName' => 'Lina',
            'lastName' => 'Moreau',
            'email' => 'lina.moreau@example.com',
            'password' => 'Password123!',
            'passwordConfirmation' => 'Password123!',
        ];

        $register = $this->postJson('/api/auth/register', $payload);
        $register->assertStatus(201)
            ->assertJsonPath('data.user.email', 'lina.moreau@example.com')
            ->assertJsonPath('data.token', fn ($token) => ! empty($token));

        $this->assertDatabaseHas('users', [
            'email' => 'lina.moreau@example.com',
            'role' => 'member',
        ]);

        $login = $this->postJson('/api/auth/login', [
            'email' => 'lina.moreau@example.com',
            'password' => 'Password123!',
        ]);

        $login->assertStatus(200)
            ->assertJsonPath('data.user.email', 'lina.moreau@example.com')
            ->assertJsonPath('data.token', fn ($token) => ! empty($token));
    }

    public function test_authenticated_user_can_manage_profile_goals_and_measurements(): void
    {
        $user = User::factory()->create([
            'first_name' => 'Lina',
            'last_name' => 'Moreau',
            'email' => 'lina.moreau@apex.app',
            'role' => 'member',
            'city' => 'Lyon',
            'age' => 28,
            'height_cm' => 168,
            'bio' => 'Original bio',
            'sport_level' => 'advanced',
            'member_since' => '2024-03-01',
        ]);

        $user->sports()->createMany([
            ['sport_key' => 'Hyrox'],
            ['sport_key' => 'Force'],
        ]);

        $this->actingAs($user, 'sanctum');

        $this->getJson('/api/me')
            ->assertStatus(200)
            ->assertJsonPath('data.firstName', 'Lina')
            ->assertJsonPath('data.lastName', 'Moreau')
            ->assertJsonPath('data.sports.0', 'Hyrox');

        $this->putJson('/api/me', [
            'firstName' => 'Lina',
            'lastName' => 'Moreau',
            'city' => 'Marseille',
            'age' => 29,
            'heightCm' => 170,
            'bio' => 'Updated bio',
            'level' => 'intermediate',
            'sports' => ['Hyrox', 'Course'],
        ])->assertStatus(200)
            ->assertJsonPath('data.city', 'Marseille')
            ->assertJsonPath('data.level', 'intermediate')
            ->assertJsonPath('data.sports.1', 'Course');

        $goal = $this->postJson('/api/me/goals', [
            'kind' => 'endurance',
            'detail' => 'Run a 10k under 50 minutes',
            'target' => '10 km < 50 min',
            'deadline' => '2026-11-15',
            'progress' => 0.74,
            'active' => true,
            'primary' => true,
        ]);

        $goal->assertStatus(201)
            ->assertJsonPath('data.kind', 'endurance')
            ->assertJsonPath('data.primary', true);

        $this->getJson('/api/me/goals')
            ->assertStatus(200)
            ->assertJsonPath('data.0.kind', 'endurance');

        $this->patchJson('/api/me/goals/' . Goal::query()->first()->id, [
            'progress' => 0.82,
            'active' => true,
        ])->assertStatus(200)
            ->assertJsonPath('data.progress', 0.82);

        $measurement = $this->postJson('/api/me/measurements', [
            'date' => '2026-09-22',
            'weightKg' => 66.4,
            'chestCm' => 88,
            'waistCm' => 71,
            'hipsCm' => 94,
            'armCm' => 29,
            'thighCm' => 54.5,
        ]);

        $measurement->assertStatus(201)
            ->assertJsonPath('data.weightKg', 66.4)
            ->assertJsonPath('data.date', '2026-09-22');

        $this->getJson('/api/me/measurements')
            ->assertStatus(200)
            ->assertJsonPath('data.0.weightKg', 66.4);

        $dashboard = $this->getJson('/api/me/dashboard');

        $dashboard->assertStatus(200)
            ->assertJsonPath('data.firstName', 'Lina')
            ->assertJsonPath('data.readiness', 0)
            ->assertJsonPath('data.streakDays', 0)
            ->assertJsonPath('data.weeklySessions', 0);
    }

    public function test_user_can_delete_goal(): void
    {
        $user = User::factory()->create();
        $this->actingAs($user, 'sanctum');

        $goal = Goal::factory()->create(['user_id' => $user->id]);

        $this->deleteJson('/api/me/goals/' . $goal->id)
            ->assertStatus(200)
            ->assertJsonPath('message', 'Goal deleted successfully.');

        $this->assertDatabaseMissing('goals', ['id' => $goal->id]);
    }

    public function test_measurement_requires_valid_payload(): void
    {
        $user = User::factory()->create();
        $this->actingAs($user, 'sanctum');

        $this->postJson('/api/me/measurements', [
            'date' => '2026-09-22',
            'weightKg' => -1,
        ])->assertStatus(422)
            ->assertJsonStructure([
                'message',
                'errors' => ['weightKg'],
            ]);
    }
}
