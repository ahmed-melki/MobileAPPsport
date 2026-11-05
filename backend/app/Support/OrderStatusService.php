<?php

namespace App\Support;

use App\Models\Order;
use App\Models\Product;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use InvalidArgumentException;

class OrderStatusService
{
    /**
     * Allowed status transitions map.
     * Note:
     * - shipped -> cancelled is strictly disallowed.
     * - cancelled orders can never transition to any status.
     * - delivered orders cannot transition anywhere.
     */
    public const ALLOWED_TRANSITIONS = [
        'pending' => ['confirmed', 'cancelled'],
        'confirmed' => ['shipped', 'cancelled'],
        'shipped' => ['delivered'],
        'delivered' => [],
        'cancelled' => [],
    ];

    /**
     * Transition an order to a new status within a transaction and row lock.
     *
     * @throws InvalidArgumentException
     */
    public function transition(
        Order|int|string $orderOrId,
        string $newStatus,
        ?User $actor = null,
        ?string $comment = null
    ): Order {
        return DB::transaction(function () use ($orderOrId, $newStatus, $actor, $comment) {
            $orderId = $orderOrId instanceof Order ? $orderOrId->id : null;
            $orderNumber = is_string($orderOrId) && ! is_numeric($orderOrId) ? $orderOrId : null;

            $query = Order::query()->lockForUpdate();

            if ($orderId !== null) {
                $query->where('id', $orderId);
            } elseif ($orderNumber !== null) {
                $query->where('order_number', $orderNumber);
            } else {
                $query->where('id', (int) $orderOrId);
            }

            $order = $query->first();

            if (! $order) {
                throw new InvalidArgumentException('Order not found.');
            }

            $currentStatus = $order->status;

            // Strict rule: cancelled order can never change
            if ($currentStatus === 'cancelled') {
                throw new InvalidArgumentException("Transition from {$currentStatus} to {$newStatus} is not allowed.");
            }

            // Check allowed transitions
            $allowed = self::ALLOWED_TRANSITIONS[$currentStatus] ?? [];
            if (! in_array($newStatus, $allowed, true)) {
                throw new InvalidArgumentException("Transition from {$currentStatus} to {$newStatus} is not allowed.");
            }

            // Restore stock once when transitioning to cancelled
            if ($newStatus === 'cancelled') {
                foreach ($order->items()->get() as $item) {
                    if ($item->product_id) {
                        Product::withTrashed()
                            ->where('id', $item->product_id)
                            ->increment('stock_quantity', $item->quantity);
                    }
                }
            }

            $updateData = ['status' => $newStatus];

            // Set payment status to paid on delivered
            if ($newStatus === 'delivered') {
                $updateData['payment_status'] = 'paid';
                $updateData['paid_at'] = now();
            }

            $order->update($updateData);

            $defaultComment = $actor
                ? "Status transitioned from {$currentStatus} to {$newStatus} by user #{$actor->id}."
                : "Status transitioned from {$currentStatus} to {$newStatus}.";

            $order->statusHistories()->create([
                'from_status' => $currentStatus,
                'to_status' => $newStatus,
                'comment' => $comment ?? $defaultComment,
                'changed_by_user_id' => $actor?->id,
            ]);

            return $order->fresh(['items.product', 'statusHistories', 'user']);
        });
    }
}
