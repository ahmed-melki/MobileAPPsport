<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class WorkoutSessionResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->slug,
            'title' => $this->title,
            'durationMin' => (int) $this->duration_min,
            'focus' => $this->focus,
            'exercises' => SessionExerciseResource::collection($this->whenLoaded('exercises')),
        ];
    }
}
