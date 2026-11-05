<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\AdminUpdateOrderStatusRequest;
use App\Http\Resources\OrderResource;
use App\Models\Order;
use App\Models\Product;
use App\Support\ApiResponse;
use App\Support\OrderStatusService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use InvalidArgumentException;

class AdminOrderController extends Controller
{
    public function __construct(
        protected OrderStatusService $orderStatusService
    ) {}

    public function index(Request $request): JsonResponse
    {
        $orders = Order::query()
            ->with(['items.product', 'statusHistories', 'user'])
            ->when($request->filled('status'), fn ($q) => $q->where('status', $request->input('status')))
            ->latest()
            ->paginate((int) $request->input('perPage', 15));

        return ApiResponse::success(OrderResource::collection($orders));
    }

    public function show(string $orderNumber): JsonResponse
    {
        $order = Order::with(['items.product', 'statusHistories', 'user'])
            ->where('order_number', $orderNumber)
            ->first();

        if (! $order) {
            return ApiResponse::error('Order not found.', [], 404);
        }

        return ApiResponse::success(new OrderResource($order));
    }

    public function updateStatus(AdminUpdateOrderStatusRequest $request, string $orderNumber): JsonResponse
    {
        $order = Order::where('order_number', $orderNumber)->first();
        if (! $order) {
            return ApiResponse::error('Order not found.', [], 404);
        }

        try {
            $updatedOrder = $this->orderStatusService->transition(
                $order,
                $request->validated('status'),
                $request->user(),
                $request->input('comment')
            );
        } catch (InvalidArgumentException $e) {
            if ($e->getMessage() === 'Order not found.') {
                return ApiResponse::error('Order not found.', [], 404);
            }

            return ApiResponse::error($e->getMessage(), [], 422);
        }

        return ApiResponse::success(
            new OrderResource($updatedOrder),
            'Order status updated successfully.'
        );
    }
}
