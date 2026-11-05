<?php

namespace Tests\Feature;

use App\Mail\OrderConfirmationMail;
use App\Models\User;
use App\Support\TrainingCatalog;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class AiRecommendationsAndOrderMailTest extends TestCase
{
    use RefreshDatabase;

    private function user(string $level, string $goal, string $equipment = 'gym'): User
    {
        return User::factory()->create([
            'sport_level' => $level,
            'experience_level' => $level === 'advanced' ? 'expert' : $level,
            'main_goal' => $goal,
            'equipment' => $equipment,
            'days_per_week' => 4,
        ]);
    }

    public function test_training_recommendation_matches_level_and_goal_without_ai_key(): void
    {
        config(['services.ai.key' => null]);
        TrainingCatalog::ensureSeeded();

        $this->actingAs($this->user('beginner', 'lose_weight'), 'sanctum');
        $beginner = $this->getJson('/api/me/ai/training')->assertOk()
            ->assertJsonPath('data.source', 'rules')
            ->assertJsonPath('data.level', 'beginner')
            ->assertJsonPath('data.plan.sets', '2–3')
            ->assertJsonPath('data.plan.reps', '12–15')
            ->json('data');
        $this->assertNotEmpty($beginner['tips']);
        $this->assertNotEmpty($beginner['exercises']);
        foreach ($beginner['exercises'] as $exercise) {
            $this->assertSame('beginner', $exercise['level']);
        }
        $this->assertSame('beginner', $beginner['programs'][0]['level']);

        $this->actingAs($this->user('advanced', 'gain_muscle'), 'sanctum');
        $advanced = $this->getJson('/api/me/ai/training')->assertOk()
            ->assertJsonPath('data.plan.sets', '4–5')
            ->json('data');
        foreach ($advanced['exercises'] as $exercise) {
            $this->assertSame('advanced', $exercise['level']);
        }
        $this->assertSame('advanced', $advanced['programs'][0]['level']);

        $this->actingAs($this->user('intermediate', 'endurance', 'home'), 'sanctum');
        $home = $this->getJson('/api/me/ai/training')->assertOk()->json('data');
        foreach ($home['exercises'] as $exercise) {
            $this->assertTrue($exercise['atHome']);
        }
    }

    public function test_training_recommendation_uses_ai_text_when_configured(): void
    {
        config(['services.ai.key' => 'test-key', 'services.ai.provider' => 'gemini']);
        Http::fake([
            '*' => Http::response(['candidates' => [['content' => ['parts' => [['text' => '```json {"summary": "Résumé IA perso", "tips": ["Conseil A", "Conseil B"]} ```']]]]]]),
        ]);
        TrainingCatalog::ensureSeeded();

        $this->actingAs($this->user('intermediate', 'gain_muscle'), 'sanctum');
        $this->getJson('/api/me/ai/training')->assertOk()
            ->assertJsonPath('data.source', 'ai')
            ->assertJsonPath('data.summary', 'Résumé IA perso')
            ->assertJsonPath('data.tips.1', 'Conseil B');
    }

    public function test_nutrition_recommendation_uses_targets_and_meals(): void
    {
        config(['services.ai.key' => null]);
        TrainingCatalog::ensureSeeded();
        \App\Support\NutritionLibrary::seed();
        $user = $this->user('beginner', 'gain_muscle');
        $user->nutritionTarget()->create(['calories' => 2800, 'protein' => 160, 'carbs' => 320, 'fat' => 80]);
        $user->mealEntries()->create([
            'date' => now()->toDateString(), 'type' => 'breakfast', 'time' => '08:00', 'name' => 'Omelette', 'calories' => 600,
            'protein' => 40, 'carbs' => 50, 'fat' => 20,
        ]);
        $this->actingAs($user, 'sanctum');

        $data = $this->getJson('/api/me/ai/nutrition?hour=12')->assertOk()
            ->assertJsonPath('data.source', 'rules')
            ->assertJsonPath('data.nextMeal', 'lunch')
            ->assertJsonPath('data.remaining.calories', 2200)
            ->json('data');

        $this->assertEquals(120, $data['remaining']['protein']);
        $this->assertNotEmpty($data['recipes']);
        $this->assertSame('lunch', $data['recipes'][0]['mealType']);
        $this->assertNotEmpty($data['foods']);
        $this->assertStringContainsString('600', $data['summary']);
    }

    public function test_order_confirmation_email_is_sent_with_purchase_details(): void
    {
        Mail::fake();
        $this->seed(DatabaseSeeder::class);
        $user = User::factory()->create(['email' => 'client@apex.app']);
        $this->actingAs($user, 'sanctum');

        $this->postJson('/api/me/cart/items', ['productId' => 'motion-tee', 'quantity' => 2])->assertOk();
        $orderNumber = $this->postJson('/api/me/orders', [
            'fullName' => 'Ahmed Melki', 'phone' => '+21698765432', 'addressLine1' => '15 Avenue Habib Bourguiba',
            'city' => 'Tunis', 'governorate' => 'Tunis', 'postalCode' => '1000', 'paymentMethod' => 'cash_on_delivery',
        ])->assertCreated()->json('data.orderNumber');

        Mail::assertSent(OrderConfirmationMail::class, function (OrderConfirmationMail $mail) use ($orderNumber) {
            $html = $mail->render();

            return $mail->hasTo('client@apex.app')
                && $mail->order->order_number === $orderNumber
                && str_contains($html, $orderNumber)
                && str_contains($html, 'Ahmed Melki')
                && str_contains($html, '178,000 DT')
                && str_contains($html, 'Paiement à la livraison');
        });
    }
}
