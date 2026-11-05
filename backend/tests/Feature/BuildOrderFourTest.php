<?php

namespace Tests\Feature;

use App\Models\CoachAvailability;
use App\Models\CoachProfile;
use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class BuildOrderFourTest extends TestCase
{
    use RefreshDatabase;

    public function test_coach_catalog_and_availability_are_public_to_authenticated_users(): void
    {
        $this->seed(DatabaseSeeder::class);
        $this->actingAs(User::where('email', 'lina.moreau@apex.app')->firstOrFail(), 'sanctum');

        $this->getJson('/api/coaches?specialty=strength')->assertOk()->assertJsonPath('data.0.id', 'lucas-meyer');
        $this->getJson('/api/coaches/marion-leroy')->assertOk()->assertJsonPath('data.id', 'marion-leroy');
        $this->getJson('/api/coaches/marion-leroy/availability')->assertOk()->assertJsonStructure(['data' => [['id', 'scheduledAt', 'status']]]);
    }

    public function test_booking_locks_availability_and_cancel_releases_it(): void
    {
        $this->seed(DatabaseSeeder::class);
        $user = User::where('email', 'lina.moreau@apex.app')->firstOrFail();
        $availability = CoachProfile::where('slug', 'antoine-bazin')->firstOrFail()->availabilities()->where('status', 'available')->firstOrFail();
        $this->actingAs($user, 'sanctum');

        $booking = $this->postJson('/api/me/bookings', ['availabilityId' => $availability->id, 'type' => 'running_plan'])
            ->assertCreated()->assertJsonPath('data.scheduledAt', $availability->scheduled_at->utc()->format('Y-m-d\\TH:i:s\\Z'));
        $bookingId = $booking->json('data.id');
        $this->assertDatabaseHas('coach_availabilities', ['id' => $availability->id, 'status' => 'booked']);

        $this->postJson('/api/me/bookings', ['availabilityId' => $availability->id, 'type' => 'duplicate'])->assertStatus(409);
        $this->patchJson('/api/me/bookings/'.$bookingId)->assertOk()->assertJsonPath('data.status', 'cancelled');
        $this->assertDatabaseHas('coach_availabilities', ['id' => $availability->id, 'status' => 'available']);
    }

    public function test_only_the_owning_coach_can_confirm_and_confirm_creates_athlete(): void
    {
        $this->seed(DatabaseSeeder::class);
        $member = User::where('email', 'lina.moreau@apex.app')->firstOrFail();
        $coach = User::where('email', 'antoine.bazin@apex.app')->firstOrFail();
        $availability = CoachProfile::where('slug', 'antoine-bazin')->firstOrFail()->availabilities()->where('status', 'available')->firstOrFail();
        $this->actingAs($member, 'sanctum');
        $booking = $this->postJson('/api/me/bookings', ['availabilityId' => $availability->id, 'type' => 'running_plan'])->json('data.id');

        $this->postJson('/api/coach/bookings/'.$booking.'/confirm')->assertStatus(403);
        $this->actingAs($coach, 'sanctum');
        $this->postJson('/api/coach/bookings/'.$booking.'/confirm')->assertOk()->assertJsonPath('data.status', 'confirmed');
        $this->assertDatabaseHas('coach_athletes', ['coach_profile_id' => $availability->coach_profile_id, 'user_id' => $member->id]);
        $this->getJson('/api/coach/athletes')->assertOk()->assertJsonPath('data.0.name', 'Lina Moreau');
    }
}
