<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class CoachResource extends JsonResource
{
    public function toArray($request): array
    {
        return ['id' => $this->slug, 'name' => $this->name, 'role' => $this->role, 'specialties' => $this->whenLoaded('specialties', fn () => $this->specialties->pluck('specialty')->values()->all(), []), 'bio' => $this->bio, 'rating' => (float) $this->rating, 'reviewCount' => (int) $this->review_count, 'sessions' => (int) $this->sessions, 'price' => (int) $this->price, 'initials' => $this->initials, 'accent' => $this->accent_key, 'isOnline' => (bool) $this->is_online];
    }
}
