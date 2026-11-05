<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\Product;
use App\Models\User;
use App\Support\OrderStatusService;
use Database\Seeders\DatabaseSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use InvalidArgumentException;
use Tests\TestCase;

class OrderStatusServiceAndFilamentAccessTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_access_panel_returns_true_only_for_admin_role(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $coach = User::factory()->create(['role' => 'coach']);
        $member = User::factory()->create(['role' => 'member']);

        $this->assertTrue($admin->canAccessPanel());
        $this->assertFalse($coach->canAccessPanel());
        $this->assertFalse($member->canAccessPanel());
    }

    public function test_order_status_service_never_allows_shipped_to_cancelled(): void
    {
        $this->seed(DatabaseSeeder::class);
        $user = User::factory()->create();
        $admin = User::where('role', 'admin')->first() ?? User::factory()->create(['role' => 'admin']);
        $order = Order::create([
            'user_id' => $user->id,
            'order_number' => 'APX-99901',
            'subtotal' => 100,
            'shipping' => 0,
            'total' => 100,
            'currency' => 'TND',
            'status' => 'shipped',
            'payment_status' => 'unpaid',
            'payment_method' => 'cash_on_delivery',
            'shipping_address' => ['fullName' => 'Test'],
        ]);

        $service = app(OrderStatusService::class);

        $this->expectException(InvalidArgumentException::class);
        $this->expectExceptionMessage('Transition from shipped to cancelled is not allowed.');

        $service->transition($order, 'cancelled', $admin);
    }

    public function test_order_status_service_never_allows_cancelled_order_to_change(): void
    {
        $this->seed(DatabaseSeeder::class);
        $user = User::factory()->create();
        $admin = User::where('role', 'admin')->first() ?? User::factory()->create(['role' => 'admin']);
        $order = Order::create([
            'user_id' => $user->id,
            'order_number' => 'APX-99902',
            'subtotal' => 100,
            'shipping' => 0,
            'total' => 100,
            'currency' => 'TND',
            'status' => 'cancelled',
            'payment_status' => 'unpaid',
            'payment_method' => 'cash_on_delivery',
            'shipping_address' => ['fullName' => 'Test'],
        ]);

        $service = app(OrderStatusService::class);

        $this->expectException(InvalidArgumentException::class);
        $this->expectExceptionMessage('Transition from cancelled to confirmed is not allowed.');

        $service->transition($order, 'confirmed', $admin);
    }

    public function test_order_status_service_restores_stock_and_sets_payment_paid_on_delivered(): void
    {
        $this->seed(DatabaseSeeder::class);
        $user = User::factory()->create();
        $admin = User::where('role', 'admin')->first() ?? User::factory()->create(['role' => 'admin']);
        $product = Product::where('slug', 'motion-tee')->firstOrFail();
        $initialStock = $product->stock_quantity;

        // Create order with 2 quantity
        $order = Order::create([
            'user_id' => $user->id,
            'order_number' => 'APX-99903',
            'subtotal' => 170,
            'shipping' => 8,
            'total' => 178,
            'currency' => 'TND',
            'status' => 'pending',
            'payment_status' => 'unpaid',
            'payment_method' => 'cash_on_delivery',
            'shipping_address' => ['fullName' => 'Test'],
        ]);

        $order->items()->create([
            'product_id' => $product->id,
            'product_name' => $product->name,
            'quantity' => 2,
            'unit_price' => 85,
            'line_total' => 170,
        ]);
        $product->decrement('stock_quantity', 2);
        $this->assertEquals($initialStock - 2, $product->fresh()->stock_quantity);

        $service = app(OrderStatusService::class);

        // Cancel restores stock
        $service->transition($order, 'cancelled', $user, 'Customer changed mind');
        $this->assertEquals('cancelled', $order->fresh()->status);
        $this->assertEquals($initialStock, $product->fresh()->stock_quantity);

        // Delivered sets payment_status = paid and paid_at
        $deliveredOrder = Order::create([
            'user_id' => $user->id,
            'order_number' => 'APX-99904',
            'subtotal' => 85,
            'shipping' => 8,
            'total' => 93,
            'currency' => 'TND',
            'status' => 'shipped',
            'payment_status' => 'unpaid',
            'payment_method' => 'cash_on_delivery',
            'shipping_address' => ['fullName' => 'Test'],
        ]);

        $this->assertNull($deliveredOrder->paid_at);
        $this->assertEquals('unpaid', $deliveredOrder->payment_status);

        $service->transition($deliveredOrder, 'delivered', $admin);
        $deliveredOrder->refresh();

        $this->assertEquals('delivered', $deliveredOrder->status);
        $this->assertEquals('paid', $deliveredOrder->payment_status);
        $this->assertNotNull($deliveredOrder->paid_at);
    }
}
