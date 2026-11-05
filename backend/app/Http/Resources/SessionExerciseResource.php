<?php

namespace App\Http\Resources;

use App\Support\LevelAdapter;
use Illuminate\Http\Resources\Json\JsonResource;

class SessionExerciseResource extends JsonResource
{
    public function toArray($request): array
    {
        $row = [
            'exerciseId' => $this->exercise_slug,
            'sets' => (int) $this->sets,
            'reps' => (int) $this->reps,
            'loadKg' => (float) ($this->load_kg ?? 0),
            'restSec' => (int) $this->rest_sec,
            'kind' => $this->kind,
            'unitNote' => $this->unit_note,
        ];

        // Prescription adapted to the logged-in user's level (easier variant, less volume for beginners).
        $row = LevelAdapter::adapt($row, LevelAdapter::userLevel($request->user()));

        return ['id' => $this->id] + $row;
    }
}
