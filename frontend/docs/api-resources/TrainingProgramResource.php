<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class TrainingProgramResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->slug,
            'title' => $this->title,
            'subtitle' => $this->subtitle,
            'weeks' => (int) $this->weeks,
            'daysPerWeek' => (int) $this->days_per_week,
            'level' => strtolower((string) $this->level),
            'goalTags' => array_values($this->goal_tags ?? []),
            'equipment' => $this->equipment,
            'sessions' => $this->whenLoaded('sessions', fn () => WorkoutSessionResource::collection($this->sessions), []),
            'sessionIds' => $this->whenLoaded('sessions', fn () => $this->sessions->pluck('slug')->values()->all(), []),
        ];
    }
}
