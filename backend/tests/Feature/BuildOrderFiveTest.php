<?php

namespace Tests\Feature;

use App\Models\Product;
use App\Models\User;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class BuildOrderFiveTest extends TestCase
{
    use RefreshDatabase;

    public function test_product_catalog_reviews_and_product_favorites_work(): void
    {
        $this->seed(DatabaseSeeder::class);
        $user = User::where('email', 'lina.moreau@apex.app')->firstOrFail();
        $this->actingAs($user, 'sanctum');

        $this->getJson('/api/products?category=shoes')->assertOk()->assertJsonPath('data.0.id', 'aero-runner-x');
        $this->getJson('/api/products/aero-runner-x')->assertOk()->assertJsonPath('data.id', 'aero-runner-x');

        $this->postJson('/api/me/favorites/products/apex-lift-02')->assertOk();
        $this->postJson('/api/me/favorites/products/apex-lift-02')->assertOk();
        $this->assertDatabaseCount('favorites', 2);
        $this->deleteJson('/api/me/favorites/products/apex-lift-02')->assertOk();

        $reviewer = User::factory()->create(['email' => 'shop-reviewer@example.com']);
        $this->actingAs($reviewer, 'sanctum');
        $this->postJson('/api/products/aero-runner-x/reviews', ['rating' => 4, 'comment' => 'Useful review.'])
            ->assertCreated()
            ->assertJsonPath('data.reviewCount', 3)
            ->assertJsonPath('data.rating', 4.5);
    }

    public function test_checkout_applies_shipping_rule_and_clears_cart(): void
    {
        $this->seed(DatabaseSeeder::class);
        $user = User::factory()->create(['email' => 'shop-order@example.com']);
        $this->actingAs($user, 'sanctum');
        $shipping = [
            'fullName' => 'Test User',
            'phone' => '+21698123456',
            'addressLine1' => '1 rue Test',
            'city' => 'Tunis',
            'governorate' => 'Tunis',
            'postalCode' => '1001',
            'paymentMethod' => 'cash_on_delivery',
        ];

        $this->postJson('/api/me/cart/items', ['productId' => 'motion-tee', 'quantity' => 1])->assertOk();
        $this->postJson('/api/me/orders', $shipping)
            ->assertCreated()
            ->assertJsonPath('data.subtotal', 85)
            ->assertJsonPath('data.shippingCost', 8)
            ->assertJsonPath('data.currency', 'TND')
            ->assertJsonPath('data.total', 93);
        $this->getJson('/api/me/cart')->assertOk()->assertJsonPath('data.itemCount', 0);

        $this->postJson('/api/me/cart/items', ['productId' => 'aero-runner-x', 'quantity' => 1])->assertOk();
        $this->postJson('/api/me/orders', $shipping)
            ->assertCreated()
            ->assertJsonPath('data.subtotal', 380)
            ->assertJsonPath('data.shippingCost', 0)
            ->assertJsonPath('data.currency', 'TND')
            ->assertJsonPath('data.total', 380);
    }

    public function test_insufficient_stock_rolls_back_order_stock_and_cart(): void
    {
        $this->seed(DatabaseSeeder::class);
        $product = Product::where('slug', 'motion-tee')->firstOrFail();
        $product->update(['stock_quantity' => 1]);
        $user = User::factory()->create(['email' => 'shop-stock@example.com']);
        $this->actingAs($user, 'sanctum');

        $this->postJson('/api/me/cart/items', ['productId' => 'motion-tee', 'quantity' => 2])->assertOk();
        $this->postJson('/api/me/orders', [
            'fullName' => 'Test',
            'phone' => '+21698123456',
            'addressLine1' => '1 rue Test',
            'city' => 'Tunis',
            'governorate' => 'Tunis',
            'postalCode' => '1001',
            'paymentMethod' => 'cash_on_delivery',
        ])->assertStatus(409);

        $this->assertDatabaseHas('products', ['id' => $product->id, 'stock_quantity' => 1]);
        $this->assertDatabaseMissing('orders', ['user_id' => $user->id]);
        $this->getJson('/api/me/cart')->assertJsonPath('data.itemCount', 2);
    }
}
