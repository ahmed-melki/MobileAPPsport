<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class SessionExerciseResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'exerciseId' => $this->exercise_slug,
            'sets' => (int) $this->sets,
            'reps' => (int) $this->reps,
            'loadKg' => (float) ($this->load_kg ?? 0),
            'restSec' => (int) $this->rest_sec,
            'kind' => $this->kind,
            'unitNote' => $this->unit_note,
        ];
    }
}
