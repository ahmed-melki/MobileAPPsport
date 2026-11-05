<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class ProductResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->slug,
            'name' => $this->name,
            'brand' => $this->brand,
            'category' => $this->category,
            'price' => round((float) $this->price, 3),
            'currency' => 'TND',
            'description' => $this->description,
            'features' => $this->features ?? [],
            'rating' => (float) $this->rating,
            'reviewCount' => (int) $this->review_count,
            'color' => $this->color_key,
            'icon' => $this->icon_key,
            'badge' => $this->badge_key,
            'stockQuantity' => (int) $this->stock_quantity,
            'isDeactivated' => $this->trashed(),
            'reviews' => $this->whenLoaded('reviews', fn () => ProductReviewResource::collection($this->reviews), []),
        ];
    }
}
