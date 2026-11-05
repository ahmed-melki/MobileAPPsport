<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class CoachBookingResource extends JsonResource
{
    public function toArray($request): array
    {
        return ['id' => $this->id, 'coachId' => $this->coach?->slug, 'coachName' => $this->coach?->name, 'scheduledAt' => $this->scheduled_at?->utc()->format('Y-m-d\TH:i:s\Z'), 'type' => $this->type, 'status' => $this->status];
    }
}
