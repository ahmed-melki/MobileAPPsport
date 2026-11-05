<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class UserProgramResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'program' => new TrainingProgramResource($this->whenLoaded('program')),
            'status' => $this->status,
            'startedAt' => $this->started_at?->toISOString(),
            'pausedAt' => $this->paused_at?->toISOString(),
        ];
    }
}
