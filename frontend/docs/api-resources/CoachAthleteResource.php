<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class CoachAthleteResource extends JsonResource
{
    public function toArray($request): array
    {
        return ['id' => $this->user_id, 'name' => trim($this->user?->first_name.' '.$this->user?->last_name), 'initials' => strtoupper(substr((string) $this->user?->first_name, 0, 1).substr((string) $this->user?->last_name, 0, 1)), 'goal' => $this->goal, 'progress' => (float) $this->progress, 'lastSession' => $this->last_session_at?->utc()->format('Y-m-d\TH:i:s\Z')];
    }
}
