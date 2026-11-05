<?php

namespace Tests\Feature;

use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminCatalogManagementTest extends TestCase
{
    use RefreshDatabase;

    protected function admin(): User
    {
        $this->seed(DatabaseSeeder::class);

        return User::where('email', 'admin@apex.app')->firstOrFail();
    }

    public function test_member_cannot_manage_catalog(): void
    {
        $this->seed(DatabaseSeeder::class);
        $this->actingAs(User::where('email', 'lina.moreau@apex.app')->firstOrFail(), 'sanctum');

        $this->getJson('/api/admin/products')->assertForbidden();
        $this->postJson('/api/admin/foods', [])->assertForbidden();
        $this->postJson('/api/admin/recipes', [])->assertForbidden();
    }

    public function test_admin_can_create_update_and_delete_a_food(): void
    {
        $this->actingAs($this->admin(), 'sanctum');

        $id = $this->postJson('/api/admin/foods', [
            'name' => 'Sandwich thon',
            'category' => 'tunisian',
            'serving' => '1 pièce',
            'calories' => 520,
            'protein' => 28,
            'carbs' => 55,
            'fat' => 20,
            'isTunisian' => true,
        ])->assertCreated()->assertJsonPath('data.isTunisian', true)->json('data.id');

        $this->assertSame('sandwich-thon', $id);
        $this->postJson('/api/admin/foods', ['name' => 'x'])->assertStatus(422);

        $this->putJson("/api/admin/foods/{$id}", ['calories' => 480])->assertOk()->assertJsonPath('data.calories', 480);
        $this->getJson('/api/nutrition/foods?search=Sandwich')->assertOk()->assertJsonPath('data.0.id', $id);

        $this->deleteJson("/api/admin/foods/{$id}")->assertOk();
        $this->getJson('/api/nutrition/foods?search=Sandwich')->assertOk()->assertJsonCount(0, 'data');
    }

    public function test_admin_can_create_update_and_delete_a_recipe(): void
    {
        $this->actingAs($this->admin(), 'sanctum');

        $id = $this->postJson('/api/admin/recipes', [
            'name' => 'Omelette tunisienne',
            'subtitle' => 'Œufs · harissa · persil',
            'calories' => 350,
            'protein' => 22,
            'carbs' => 6,
            'fat' => 25,
            'duration' => 10,
            'mealType' => 'breakfast',
            'goalTags' => ['maintain', 'gain_muscle'],
            'ingredients' => ['3 œufs', 'Harissa'],
            'steps' => ['Battre les œufs.', 'Cuire.'],
            'isTunisian' => true,
        ])->assertCreated()->assertJsonPath('data.mealType', 'breakfast')->json('data.id');

        $this->putJson("/api/admin/recipes/{$id}", ['steps' => ['Une seule étape.']])
            ->assertOk()
            ->assertJsonPath('data.steps.0', 'Une seule étape.');

        $this->assertNotNull(collect($this->getJson('/api/nutrition/recipes')->json('data'))->firstWhere('id', $id));

        $this->deleteJson("/api/admin/recipes/{$id}")->assertOk();
        $this->assertNull(collect($this->getJson('/api/nutrition/recipes')->json('data'))->firstWhere('id', $id));
    }

    public function test_admin_product_list_includes_deactivated_and_can_restore(): void
    {
        $this->actingAs($this->admin(), 'sanctum');

        $slug = $this->postJson('/api/admin/products', [
            'name' => 'Ceinture de force',
            'brand' => 'Apex',
            'category' => 'strength',
            'price' => 89.5,
            'description' => 'Ceinture en cuir.',
            'features' => ['Cuir', '10 mm'],
            'colorKey' => 'coral',
            'iconKey' => 'fitness_center',
            'stockQuantity' => 12,
        ])->assertCreated()->json('data.id');

        $this->patchJson("/api/admin/products/{$slug}/deactivate")->assertOk();
        $row = collect($this->getJson('/api/admin/products')->assertOk()->json('data'))->firstWhere('id', $slug);
        $this->assertTrue($row['isDeactivated']);

        $this->patchJson("/api/admin/products/{$slug}/restore")->assertOk()->assertJsonPath('data.isDeactivated', false);
    }
}
