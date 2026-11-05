<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class CoachAvailabilityResource extends JsonResource
{
    public function toArray($request): array
    {
        return ['id' => $this->id, 'scheduledAt' => $this->scheduled_at?->utc()->format('Y-m-d\TH:i:s\Z'), 'durationMin' => (int) $this->duration_min, 'status' => $this->status];
    }
}
