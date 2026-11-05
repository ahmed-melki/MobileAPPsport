<?php

namespace Tests\Feature;

use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class BuildOrderThreeTest extends TestCase
{
    use RefreshDatabase;

    public function test_nutrition_summary_targets_catalog_and_favorites_work(): void
    {
        $this->seed(DatabaseSeeder::class);
        $user = User::where('email', 'lina.moreau@apex.app')->firstOrFail();
        $this->actingAs($user, 'sanctum');

        $this->getJson('/api/me/nutrition/summary?date='.now()->toDateString())
            ->assertOk()
            ->assertJsonPath('data.totals.calories', 1490)
            ->assertJsonPath('data.totals.protein', 104)
            ->assertJsonPath('data.targets.calories', 2350);

        $this->getJson('/api/nutrition/recipes')->assertOk()->assertJsonFragment(['id' => 'power-bowl']);
        $this->getJson('/api/nutrition/foods?search=Skyr')->assertOk()->assertJsonPath('data.0.id', 'plain-skyr');
        $this->getJson('/api/me/favorites/recipes')->assertOk()->assertJsonPath('data.0.id', 'power-bowl');

        $this->postJson('/api/me/favorites/recipes/power-bowl')->assertCreated();
        $this->postJson('/api/me/favorites/recipes/power-bowl')->assertCreated();
        $this->assertDatabaseCount('user_favorite_recipes', 1);
    }

    public function test_meals_are_owned_and_totals_are_computed_from_entries(): void
    {
        $this->seed(DatabaseSeeder::class);
        $user = User::factory()->create(['email' => 'nutrition-owner@example.com']);
        $other = User::factory()->create(['email' => 'nutrition-other@example.com']);
        $this->actingAs($user, 'sanctum');

        $response = $this->postJson('/api/me/meals', [
            'date' => '2026-10-10', 'type' => 'dinner', 'name' => 'Test dinner', 'time' => '19:30',
            'calories' => 600, 'protein' => 40, 'carbs' => 50, 'fat' => 20,
        ])->assertCreated();
        $mealId = $response->json('data.id');

        $other->mealEntries()->create(['date' => '2026-10-10', 'type' => 'lunch', 'name' => 'Other lunch', 'time' => '12:00', 'calories' => 1, 'protein' => 1, 'carbs' => 1, 'fat' => 1]);
        $this->getJson('/api/me/meals?date=2026-10-10')->assertOk()->assertJsonPath('data.0.id', $mealId);
        $this->putJson('/api/me/meals/'.$other->mealEntries()->first()->id, ['name' => 'No access'])->assertStatus(403);
        $this->deleteJson('/api/me/meals/'.$mealId)->assertOk();
    }

    public function test_nutrition_target_validation_is_returned(): void
    {
        $this->seed(DatabaseSeeder::class);
        $this->actingAs(User::factory()->create(['email' => 'nutrition-validation@example.com']), 'sanctum');
        $this->putJson('/api/me/nutrition-targets', ['calories' => -1, 'protein' => 0, 'carbs' => 0, 'fat' => 0])
            ->assertStatus(422)->assertJsonValidationErrors(['calories']);
    }
}
