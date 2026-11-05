<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class ProductReviewResource extends JsonResource
{
    public function toArray($request): array
    {
        $name = trim(($this->user?->first_name ?? '').' '.($this->user?->last_name ?? ''));
        return ['id' => $this->id, 'author' => $name ?: 'Apex member', 'date' => $this->created_at?->format('Y-m-d'), 'rating' => (float) $this->rating, 'comment' => $this->comment, 'initials' => strtoupper(substr((string) $this->user?->first_name, 0, 1).substr((string) $this->user?->last_name, 0, 1))];
    }
}
