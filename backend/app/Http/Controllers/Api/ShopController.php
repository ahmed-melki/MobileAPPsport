<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreCartItemRequest;
use App\Http\Requests\StoreOrderRequest;
use App\Http\Requests\StoreProductReviewRequest;
use App\Http\Requests\UpdateCartItemRequest;
use App\Http\Resources\CartResource;
use App\Http\Resources\OrderResource;
use App\Http\Resources\ProductResource;
use App\Models\Cart;
use App\Models\Order;
use App\Models\Product;
use App\Support\ApiResponse;
use App\Support\TunisianGovernorates;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use RuntimeException;

class ShopController extends Controller
{
    public function governorates(): JsonResponse
    {
        return ApiResponse::success(TunisianGovernorates::all(), 'Governorates retrieved successfully.');
    }

    public function products(Request $request): JsonResponse
    {
        $products = Product::query()
            ->when($request->filled('category'), fn ($q) => $q->where('category', $request->category))
            ->when($request->filled('search'), fn ($q) => $q->where(fn ($search) => $search->where('name', 'like', '%'.$request->string('search').'%')->orWhere('brand', 'like', '%'.$request->string('search').'%')))
            ->orderBy('name')
            ->paginate((int) $request->input('perPage', 20));

        return ApiResponse::success(ProductResource::collection($products));
    }

    public function product(string $slug): JsonResponse
    {
        $product = Product::with(['reviews.user'])->where('slug', $slug)->firstOrFail();

        return ApiResponse::success(new ProductResource($product));
    }

    public function review(StoreProductReviewRequest $request, string $slug): JsonResponse
    {
        $product = Product::where('slug', $slug)->firstOrFail();
        $review = $product->reviews()->updateOrCreate(
            ['user_id' => $request->user()->id],
            ['rating' => $request->rating, 'comment' => $request->comment]
        );
        $product->update([
            'rating' => round((float) $product->reviews()->avg('rating'), 2),
            'review_count' => $product->reviews()->count(),
        ]);

        return ApiResponse::success(new ProductResource($product->fresh(['reviews.user'])), 'Review saved successfully.', [], 201);
    }

    public function favorites(Request $request): JsonResponse
    {
        return ApiResponse::success(ProductResource::collection(
            $request->user()->productFavorites()->with('product')->get()->pluck('product')
        ));
    }

    public function favorite(Request $request, string $slug): JsonResponse
    {
        $product = Product::where('slug', $slug)->firstOrFail();
        $request->user()->productFavorites()->firstOrCreate(['product_id' => $product->id]);

        return ApiResponse::success(new ProductResource($product), 'Product favorited successfully.');
    }

    public function unfavorite(Request $request, string $slug): JsonResponse
    {
        $request->user()->productFavorites()->whereHas('product', fn ($q) => $q->where('slug', $slug))->delete();

        return ApiResponse::success(null, 'Product unfavorited successfully.');
    }

    public function cart(Request $request): JsonResponse
    {
        $cart = $request->user()->cart()->firstOrCreate([])->load('items.product');

        return ApiResponse::success(new CartResource($cart));
    }

    public function addCartItem(StoreCartItemRequest $request): JsonResponse
    {
        $product = Product::where('slug', $request->productId)->firstOrFail();
        $cart = $request->user()->cart()->firstOrCreate([]);
        $item = $cart->items()->firstOrNew(['product_id' => $product->id]);
        $item->quantity = ($item->exists ? $item->quantity : 0) + $request->quantity;
        $item->save();

        return ApiResponse::success(new CartResource($cart->load('items.product')), 'Cart updated successfully.');
    }

    public function updateCartItem(UpdateCartItemRequest $request, string $slug): JsonResponse
    {
        $item = $request->user()->cart()->firstOrCreate([])->items()->whereHas('product', fn ($q) => $q->where('slug', $slug))->first();
        if (! $item) {
            return ApiResponse::error('Cart item not found.', [], 404);
        }
        $item->update(['quantity' => $request->quantity]);

        return ApiResponse::success(new CartResource($item->cart->load('items.product')), 'Cart updated successfully.');
    }

    public function deleteCartItem(Request $request, string $slug): JsonResponse
    {
        $cart = $request->user()->cart()->firstOrCreate([]);
        $item = $cart->items()->whereHas('product', fn ($q) => $q->where('slug', $slug))->first();
        if (! $item) {
            return ApiResponse::error('Cart item not found.', [], 404);
        }
        $item->delete();

        return ApiResponse::success(new CartResource($cart->load('items.product')), 'Cart updated successfully.');
    }

    public function orders(Request $request): JsonResponse
    {
        $orders = $request->user()->orders()
            ->with(['items.product', 'statusHistories'])
            ->orderByDesc('created_at')
            ->get();

        return ApiResponse::success(OrderResource::collection($orders));
    }

    public function showOrder(Request $request, string $orderNumber): JsonResponse
    {
        $order = $request->user()->orders()
            ->with(['items.product', 'statusHistories'])
            ->where('order_number', $orderNumber)
            ->first();

        if (! $order) {
            return ApiResponse::error('Order not found.', [], 404);
        }

        return ApiResponse::success(new OrderResource($order));
    }

    public function createOrder(StoreOrderRequest $request): JsonResponse
    {
        try {
            $order = DB::transaction(function () use ($request) {
                $cart = Cart::where('user_id', $request->user()->id)->lockForUpdate()->first();
                if (! $cart) {
                    throw new RuntimeException('Cart is empty.');
                }
                $items = $cart->items()->get();
                if ($items->isEmpty()) {
                    throw new RuntimeException('Cart is empty.');
                }

                $lines = [];
                $subtotal = 0;
                foreach ($items as $item) {
                    $product = Product::lockForUpdate()->find($item->product_id);
                    if (! $product || $product->stock_quantity < $item->quantity) {
                        throw new RuntimeException('Insufficient stock for '.($product?->name ?? $item->product_id).'.');
                    }
                    $unitPrice = round((float) $product->price, 3);
                    $lineTotal = round($unitPrice * $item->quantity, 3);
                    $subtotal += $lineTotal;
                    $lines[] = [$product, $item->quantity, $unitPrice, $lineTotal];
                }

                $subtotal = round($subtotal, 3);
                $freeShippingThreshold = (float) config('shop.free_shipping_threshold', 250.000);
                $shippingFee = (float) config('shop.shipping_fee', 8.000);
                $shipping = $subtotal >= $freeShippingThreshold ? 0.000 : $shippingFee;
                $total = round($subtotal + $shipping, 3);

                $canonicalGov = TunisianGovernorates::canonical($request->input('governorate')) ?? $request->input('governorate');
                $shippingAddress = [
                    'fullName' => $request->input('fullName'),
                    'phone' => $request->input('phone'),
                    'addressLine1' => $request->input('addressLine1'),
                    'addressLine2' => $request->input('addressLine2'),
                    'city' => $request->input('city'),
                    'governorate' => $canonicalGov,
                    'postalCode' => $request->input('postalCode'),
                ];

                $orderNumber = 'APX-'.str_pad((string) ((Order::max('id') ?? 0) + 20502), 5, '0', STR_PAD_LEFT);

                $order = $request->user()->orders()->create([
                    'order_number' => $orderNumber,
                    'subtotal' => $subtotal,
                    'shipping' => $shipping,
                    'total' => $total,
                    'currency' => 'TND',
                    'status' => 'pending',
                    'payment_status' => 'unpaid',
                    'payment_method' => $request->input('paymentMethod', 'cash_on_delivery'),
                    'paid_at' => null,
                    'shipping_address' => $shippingAddress,
                    'notes' => $request->input('notes'),
                ]);

                foreach ($lines as [$product, $quantity, $unitPrice, $lineTotal]) {
                    $order->items()->create([
                        'product_id' => $product->id,
                        'product_name' => $product->name,
                        'quantity' => $quantity,
                        'unit_price' => $unitPrice,
                        'line_total' => $lineTotal,
                    ]);
                    $product->decrement('stock_quantity', $quantity);
                }

                $order->statusHistories()->create([
                    'from_status' => null,
                    'to_status' => 'pending',
                    'comment' => 'Order placed by customer.',
                    'changed_by_user_id' => $request->user()->id,
                ]);

                $cart->items()->delete();

                return $order->load(['items.product', 'statusHistories']);
            });
        } catch (RuntimeException $exception) {
            return ApiResponse::error($exception->getMessage(), [], 409);
        }

        // Confirmation email (never blocks the order if the mail server fails).
        try {
            \Illuminate\Support\Facades\Mail::to($request->user()->email)->send(new \App\Mail\OrderConfirmationMail($order));
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::warning('Order confirmation mail failed: '.$e->getMessage());
        }

        return ApiResponse::success(new OrderResource($order), 'Order created successfully.', [], 201);
    }

    public function cancelOrder(Request $request, string $orderNumber, \App\Support\OrderStatusService $orderStatusService): JsonResponse
    {
        $order = Order::where('user_id', $request->user()->id)
            ->where('order_number', $orderNumber)
            ->first();

        if (! $order) {
            return ApiResponse::error('Order not found.', [], 404);
        }

        if ($order->status !== 'pending') {
            return ApiResponse::error('Only pending orders can be cancelled.', [], 422);
        }

        try {
            $updatedOrder = $orderStatusService->transition(
                $order,
                'cancelled',
                $request->user(),
                $request->input('comment', 'Order cancelled by customer.')
            );
        } catch (RuntimeException|\InvalidArgumentException $exception) {
            return ApiResponse::error($exception->getMessage(), [], 422);
        }

        return ApiResponse::success(
            new OrderResource($updatedOrder),
            'Order cancelled successfully.'
        );
    }
}
