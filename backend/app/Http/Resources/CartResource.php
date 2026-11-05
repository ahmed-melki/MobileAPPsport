<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class CartResource extends JsonResource
{
    public function toArray($request): array
    {
        $items = $this->items ?? collect();
        $subtotal = $items->sum(fn ($item) => (float) $item->product->price * $item->quantity);
        return [
            'id' => $this->id,
            'items' => $items->map(fn ($item) => [
                'id' => $item->id,
                'product' => new ProductResource($item->product),
                'quantity' => (int) $item->quantity,
                'lineTotal' => round((float) $item->product->price * $item->quantity, 3),
            ])->values(),
            'currency' => 'TND',
            'subtotal' => round((float) $subtotal, 3),
            'itemCount' => (int) $items->sum('quantity'),
        ];
    }
}
