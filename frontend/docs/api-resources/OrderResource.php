<?php

namespace App\Http\Resources;

use App\Models\Product;
use Illuminate\Http\Resources\Json\JsonResource;

class OrderResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->order_number,
            'orderNumber' => $this->order_number,
            'date' => $this->created_at?->format('Y-m-d'),
            'createdAt' => $this->created_at?->toISOString(),
            'status' => $this->status,
            'paymentStatus' => $this->payment_status,
            'paymentMethod' => $this->payment_method ?? 'cash_on_delivery',
            'paidAt' => $this->paid_at?->toISOString(),
            'currency' => $this->currency ?? 'TND',
            'subtotal' => round((float) $this->subtotal, 3),
            'shippingCost' => round((float) $this->shipping, 3),
            'total' => round((float) $this->total, 3),
            'notes' => $this->notes,
            'shippingAddress' => $this->shipping_address,
            'items' => $this->whenLoaded('items', fn () => $this->items->map(function ($item) {
                $slug = $item->product?->slug;
                if (! $slug && $item->product_id) {
                    $slug = Product::withTrashed()->find($item->product_id)?->slug;
                }

                return [
                    'productId' => $slug,
                    'productName' => $item->product_name,
                    'quantity' => (int) $item->quantity,
                    'unitPrice' => round((float) $item->unit_price, 3),
                    'lineTotal' => round((float) $item->line_total, 3),
                ];
            })->values(), []),
            'statusHistory' => OrderStatusHistoryResource::collection(
                $this->whenLoaded('statusHistories', fn () => $this->statusHistories, [])
            ),
        ];
    }
}
