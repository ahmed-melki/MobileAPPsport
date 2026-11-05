<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\Product;
use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ShopTunisiaOrderAndAdminTest extends TestCase
{
    use RefreshDatabase;

    private function validCheckoutPayload(array $overrides = []): array
    {
        return array_merge([
            'fullName' => 'Firas Chahed',
            'phone' => '+21698765432',
            'addressLine1' => '15 Avenue Habib Bourguiba',
            'addressLine2' => 'Appartement 4B',
            'city' => 'Tunis',
            'governorate' => 'Tunis',
            'postalCode' => '1000',
            'notes' => 'Livraison l’après-midi svp',
            'paymentMethod' => 'cash_on_delivery',
        ], $overrides);
    }

    public function test_shop_governorates_returns_all_24_tunisian_governorates(): void
    {
        $response = $this->getJson('/api/shop/governorates')
            ->assertOk()
            ->assertJsonPath('message', 'Governorates retrieved successfully.');

        $governorates = $response->json('data');
        $this->assertCount(24, $governorates);
        $this->assertContains('Tunis', $governorates);
        $this->assertContains('Sfax', $governorates);
        $this->assertContains('Sousse', $governorates);
        $this->assertContains('Béja', $governorates);
    }

    public function test_checkout_phone_validation(): void
    {
        $this->seed(DatabaseSeeder::class);
        $user = User::factory()->create(['email' => 'phone-test@apex.app']);
        $this->actingAs($user, 'sanctum');

        $this->postJson('/api/me/cart/items', ['productId' => 'motion-tee', 'quantity' => 1])->assertOk();

        // 7 digits: invalid
        $this->postJson('/api/me/orders', $this->validCheckoutPayload(['phone' => '1234567']))
            ->assertStatus(422)
            ->assertJsonValidationErrors('phone');

        // Letters: invalid
        $this->postJson('/api/me/orders', $this->validCheckoutPayload(['phone' => 'abcdefgh']))
            ->assertStatus(422)
            ->assertJsonValidationErrors('phone');

        // 9 digits without +216: invalid
        $this->postJson('/api/me/orders', $this->validCheckoutPayload(['phone' => '123456789']))
            ->assertStatus(422)
            ->assertJsonValidationErrors('phone');

        // 8 digits: valid
        $this->postJson('/api/me/orders', $this->validCheckoutPayload(['phone' => '98765432']))
            ->assertCreated();

        // +216 + 8 digits: valid
        $this->postJson('/api/me/cart/items', ['productId' => 'motion-tee', 'quantity' => 1])->assertOk();
        $this->postJson('/api/me/orders', $this->validCheckoutPayload(['phone' => '+21698765432']))
            ->assertCreated();
    }

    public function test_checkout_governorate_validation(): void
    {
        $this->seed(DatabaseSeeder::class);
        $user = User::factory()->create(['email' => 'gov-test@apex.app']);
        $this->actingAs($user, 'sanctum');

        $this->postJson('/api/me/cart/items', ['productId' => 'motion-tee', 'quantity' => 1])->assertOk();

        // Foreign or invalid governorate
        $this->postJson('/api/me/orders', $this->validCheckoutPayload(['governorate' => 'Paris']))
            ->assertStatus(422)
            ->assertJsonValidationErrors('governorate');

        // Valid Tunisian governorates (with or without accents)
        $this->postJson('/api/me/orders', $this->validCheckoutPayload(['governorate' => 'Beja']))
            ->assertCreated()
            ->assertJsonPath('data.shippingAddress.governorate', 'Béja');
    }

    public function test_new_order_is_pending_and_unpaid_with_history_and_stock_deducted(): void
    {
        $this->seed(DatabaseSeeder::class);
        $user = User::factory()->create(['email' => 'new-order@apex.app']);
        $this->actingAs($user, 'sanctum');

        $product = Product::where('slug', 'motion-tee')->firstOrFail();
        $initialStock = $product->stock_quantity;

        $this->postJson('/api/me/cart/items', ['productId' => 'motion-tee', 'quantity' => 2])->assertOk();
        $response = $this->postJson('/api/me/orders', $this->validCheckoutPayload())
            ->assertCreated()
            ->assertJsonPath('data.status', 'pending')
            ->assertJsonPath('data.paymentStatus', 'unpaid')
            ->assertJsonPath('data.paymentMethod', 'cash_on_delivery')
            ->assertJsonPath('data.currency', 'TND')
            ->assertJsonPath('data.subtotal', 170)
            ->assertJsonPath('data.shippingCost', 8)
            ->assertJsonPath('data.total', 178);

        $orderNumber = $response->json('data.orderNumber');
        $this->assertDatabaseHas('products', ['id' => $product->id, 'stock_quantity' => $initialStock - 2]);
        $this->assertDatabaseHas('order_status_histories', [
            'to_status' => 'pending',
            'from_status' => null,
            'changed_by_user_id' => $user->id,
        ]);

        $orderDetail = $this->getJson("/api/me/orders/{$orderNumber}")
            ->assertOk()
            ->assertJsonPath('data.orderNumber', $orderNumber)
            ->assertJsonPath('data.shippingAddress.fullName', 'Firas Chahed')
            ->assertJsonPath('data.notes', 'Livraison l’après-midi svp')
            ->assertJsonPath('data.statusHistory.0.toStatus', 'pending');

        $this->assertNotNull($orderDetail->json('data.createdAt'));
    }

    public function test_customer_can_cancel_pending_order_and_stock_is_restored(): void
    {
        $this->seed(DatabaseSeeder::class);
        $user = User::factory()->create(['email' => 'cancel-user@apex.app']);
        $this->actingAs($user, 'sanctum');

        $product = Product::where('slug', 'motion-tee')->firstOrFail();
        $initialStock = $product->stock_quantity;

        $this->postJson('/api/me/cart/items', ['productId' => 'motion-tee', 'quantity' => 2])->assertOk();
        $createRes = $this->postJson('/api/me/orders', $this->validCheckoutPayload())->assertCreated();
        $orderNumber = $createRes->json('data.orderNumber');

        $this->assertEquals($initialStock - 2, $product->fresh()->stock_quantity);

        $cancelRes = $this->postJson("/api/me/orders/{$orderNumber}/cancel", ['comment' => 'Changed my mind'])
            ->assertOk()
            ->assertJsonPath('data.status', 'cancelled');

        $this->assertEquals($initialStock, $product->fresh()->stock_quantity);

        $this->assertDatabaseHas('order_status_histories', [
            'from_status' => 'pending',
            'to_status' => 'cancelled',
            'changed_by_user_id' => $user->id,
        ]);
    }

    public function test_double_cancel_restores_stock_once(): void
    {
        $this->seed(DatabaseSeeder::class);
        $user = User::factory()->create(['email' => 'double-cancel@apex.app']);
        $this->actingAs($user, 'sanctum');

        $product = Product::where('slug', 'motion-tee')->firstOrFail();
        $initialStock = $product->stock_quantity;

        $this->postJson('/api/me/cart/items', ['productId' => 'motion-tee', 'quantity' => 2])->assertOk();
        $createRes = $this->postJson('/api/me/orders', $this->validCheckoutPayload())->assertCreated();
        $orderNumber = $createRes->json('data.orderNumber');

        // First cancel: succeeds, stock restored
        $this->postJson("/api/me/orders/{$orderNumber}/cancel")->assertOk();
        $this->assertEquals($initialStock, $product->fresh()->stock_quantity);

        // Second cancel: rejected with 422, stock is NOT restored a second time
        $this->postJson("/api/me/orders/{$orderNumber}/cancel")
            ->assertStatus(422)
            ->assertJsonPath('message', 'Only pending orders can be cancelled.');

        $this->assertEquals($initialStock, $product->fresh()->stock_quantity);
    }

    public function test_customer_cannot_cancel_confirmed_or_shipped_order(): void
    {
        $this->seed(DatabaseSeeder::class);
        $user = User::factory()->create(['email' => 'non-pending-cancel@apex.app']);
        $this->actingAs($user, 'sanctum');

        $this->postJson('/api/me/cart/items', ['productId' => 'motion-tee', 'quantity' => 1])->assertOk();
        $createRes = $this->postJson('/api/me/orders', $this->validCheckoutPayload())->assertCreated();
        $orderNumber = $createRes->json('data.orderNumber');

        $order = Order::where('order_number', $orderNumber)->firstOrFail();
        $order->update(['status' => 'confirmed']);

        $this->postJson("/api/me/orders/{$orderNumber}/cancel")
            ->assertStatus(422)
            ->assertJsonPath('message', 'Only pending orders can be cancelled.');
    }

    public function test_another_users_order_returns_404(): void
    {
        $this->seed(DatabaseSeeder::class);
        $userA = User::factory()->create(['email' => 'usera@apex.app']);
        $userB = User::factory()->create(['email' => 'userb@apex.app']);

        $this->actingAs($userA, 'sanctum');
        $this->postJson('/api/me/cart/items', ['productId' => 'motion-tee', 'quantity' => 1])->assertOk();
        $createRes = $this->postJson('/api/me/orders', $this->validCheckoutPayload())->assertCreated();
        $orderNumber = $createRes->json('data.orderNumber');

        // User B tries to view or cancel User A's order -> 404
        $this->actingAs($userB, 'sanctum');
        $this->getJson("/api/me/orders/{$orderNumber}")->assertStatus(404);
        $this->postJson("/api/me/orders/{$orderNumber}/cancel")->assertStatus(404);
    }

    public function test_non_admin_gets_403_on_admin_routes(): void
    {
        $this->seed(DatabaseSeeder::class);
        $user = User::factory()->create(['email' => 'regular-user@apex.app', 'role' => 'member']);
        $this->actingAs($user, 'sanctum');

        $this->getJson('/api/admin/orders')->assertStatus(403);
        $this->getJson('/api/admin/orders/APX-20481')->assertStatus(403);
        $this->patchJson('/api/admin/orders/APX-20481/status', ['status' => 'confirmed'])->assertStatus(403);
        $this->postJson('/api/admin/products', [])->assertStatus(403);
        $this->putJson('/api/admin/products/motion-tee', [])->assertStatus(403);
        $this->patchJson('/api/admin/products/motion-tee/stock', ['stockQuantity' => 10])->assertStatus(403);
        $this->patchJson('/api/admin/products/motion-tee/deactivate')->assertStatus(403);
    }

    public function test_admin_order_transitions_and_rules(): void
    {
        $this->seed(DatabaseSeeder::class);
        $admin = User::where('email', 'admin@apex.app')->firstOrFail();
        $this->actingAs($admin, 'sanctum');

        // Admin lists orders with filter
        $this->getJson('/api/admin/orders?status=delivered')->assertOk();

        // Create a new order via customer
        $customer = User::factory()->create(['email' => 'flow-customer@apex.app']);
        $this->actingAs($customer, 'sanctum');
        $this->postJson('/api/me/cart/items', ['productId' => 'motion-tee', 'quantity' => 1])->assertOk();
        $createRes = $this->postJson('/api/me/orders', $this->validCheckoutPayload())->assertCreated();
        $orderNumber = $createRes->json('data.orderNumber');

        // Admin inspects order
        $this->actingAs($admin, 'sanctum');
        $this->getJson("/api/admin/orders/{$orderNumber}")
            ->assertOk()
            ->assertJsonPath('data.status', 'pending');

        // Invalid transition: pending -> delivered (must be rejected)
        $this->patchJson("/api/admin/orders/{$orderNumber}/status", ['status' => 'delivered'])
            ->assertStatus(422);

        // Valid transition: pending -> confirmed
        $this->patchJson("/api/admin/orders/{$orderNumber}/status", ['status' => 'confirmed'])
            ->assertOk()
            ->assertJsonPath('data.status', 'confirmed');

        // Valid transition: confirmed -> shipped
        $this->patchJson("/api/admin/orders/{$orderNumber}/status", ['status' => 'shipped'])
            ->assertOk()
            ->assertJsonPath('data.status', 'shipped');

        // Invalid transition: shipped -> cancelled (must be rejected)
        $this->patchJson("/api/admin/orders/{$orderNumber}/status", ['status' => 'cancelled'])
            ->assertStatus(422);

        // Valid transition: shipped -> delivered
        $deliveredRes = $this->patchJson("/api/admin/orders/{$orderNumber}/status", ['status' => 'delivered'])
            ->assertOk()
            ->assertJsonPath('data.status', 'delivered')
            ->assertJsonPath('data.paymentStatus', 'paid');

        $this->assertNotNull($deliveredRes->json('data.paidAt'));

        // Delivered order cannot transition anywhere
        $this->patchJson("/api/admin/orders/{$orderNumber}/status", ['status' => 'cancelled'])
            ->assertStatus(422);
    }

    public function test_admin_cancelling_confirmed_order_restores_stock(): void
    {
        $this->seed(DatabaseSeeder::class);
        $admin = User::where('email', 'admin@apex.app')->firstOrFail();
        $customer = User::factory()->create(['email' => 'admin-cancel@apex.app']);

        $product = Product::where('slug', 'motion-tee')->firstOrFail();
        $initialStock = $product->stock_quantity;

        $this->actingAs($customer, 'sanctum');
        $this->postJson('/api/me/cart/items', ['productId' => 'motion-tee', 'quantity' => 2])->assertOk();
        $createRes = $this->postJson('/api/me/orders', $this->validCheckoutPayload())->assertCreated();
        $orderNumber = $createRes->json('data.orderNumber');

        $this->actingAs($admin, 'sanctum');
        $this->patchJson("/api/admin/orders/{$orderNumber}/status", ['status' => 'confirmed'])->assertOk();
        $this->assertEquals($initialStock - 2, $product->fresh()->stock_quantity);

        // Admin cancels confirmed order
        $this->patchJson("/api/admin/orders/{$orderNumber}/status", ['status' => 'cancelled'])->assertOk();
        $this->assertEquals($initialStock, $product->fresh()->stock_quantity);

        // Cancelled order cannot transition to anything
        $this->patchJson("/api/admin/orders/{$orderNumber}/status", ['status' => 'confirmed'])->assertStatus(422);
    }

    public function test_admin_product_crud_and_validations(): void
    {
        $this->seed(DatabaseSeeder::class);
        $admin = User::where('email', 'admin@apex.app')->firstOrFail();
        $this->actingAs($admin, 'sanctum');

        // Validation: price >= 0, stockQuantity >= 0, rating/reviewCount forbidden
        $this->postJson('/api/admin/products', [
            'name' => 'Bad Product',
            'brand' => 'Apex',
            'category' => 'accessories',
            'price' => -10,
            'stockQuantity' => -5,
            'description' => 'Desc',
            'colorKey' => 'black',
            'iconKey' => 'star',
            'rating' => 5,
        ])->assertStatus(422)
          ->assertJsonValidationErrors(['price', 'stockQuantity', 'rating']);

        // Create valid product
        $createRes = $this->postJson('/api/admin/products', [
            'name' => 'Tunisia Power Belt',
            'slug' => 'tunisia-power-belt',
            'brand' => 'Apex Lift',
            'category' => 'strength',
            'price' => 145.500,
            'description' => 'Ceinture de force en cuir véritable 10mm.',
            'features' => ['Cuir 10 mm', 'Boucle levier acier'],
            'colorKey' => 'black',
            'iconKey' => 'fitness_center',
            'badgeKey' => 'new',
            'stockQuantity' => 15,
        ])->assertCreated()
          ->assertJsonPath('data.id', 'tunisia-power-belt')
          ->assertJsonPath('data.currency', 'TND')
          ->assertJsonPath('data.price', 145.5);

        // Update product
        $this->putJson('/api/admin/products/tunisia-power-belt', [
            'price' => 155.000,
            'description' => 'Ceinture de force mise à jour.',
        ])->assertOk()
          ->assertJsonPath('data.price', 155);

        // Update stock
        $this->patchJson('/api/admin/products/tunisia-power-belt/stock', [
            'stockQuantity' => 25,
        ])->assertOk()
          ->assertJsonPath('data.stockQuantity', 25);

        // Deactivate
        $this->patchJson('/api/admin/products/tunisia-power-belt/deactivate')
            ->assertOk()
            ->assertJsonPath('data.isDeactivated', true);

        $this->assertSoftDeleted('products', ['slug' => 'tunisia-power-belt']);
    }

    public function test_order_keeps_product_name_and_price_after_product_is_deactivated(): void
    {
        $this->seed(DatabaseSeeder::class);
        $admin = User::where('email', 'admin@apex.app')->firstOrFail();
        $customer = User::factory()->create(['email' => 'persist-order@apex.app']);

        $this->actingAs($customer, 'sanctum');
        $this->postJson('/api/me/cart/items', ['productId' => 'velocity-shorts', 'quantity' => 2])->assertOk();
        $createRes = $this->postJson('/api/me/orders', $this->validCheckoutPayload())->assertCreated();
        $orderNumber = $createRes->json('data.orderNumber');

        // Admin deactivates the product
        $this->actingAs($admin, 'sanctum');
        $this->patchJson('/api/admin/products/velocity-shorts/deactivate')->assertOk();

        // Customer views the order: items must still retain product name, unit price, and line total
        $this->actingAs($customer, 'sanctum');
        $orderRes = $this->getJson("/api/me/orders/{$orderNumber}")->assertOk();

        $items = $orderRes->json('data.items');
        $this->assertCount(1, $items);
        $this->assertEquals('Velocity Shorts', $items[0]['productName']);
        $this->assertEquals(95.0, $items[0]['unitPrice']);
        $this->assertEquals(190.0, $items[0]['lineTotal']);
        $this->assertEquals('velocity-shorts', $items[0]['productId']);
    }
}
