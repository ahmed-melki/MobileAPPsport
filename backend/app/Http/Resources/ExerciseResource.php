<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class ExerciseResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->slug,
            'name' => $this->name,
            'category' => $this->category,
            'muscleGroup' => $this->muscle_group ?? 'full_body',
            'level' => $this->level ?? 'beginner',
            'kind' => $this->kind ?? 'load',
            'atHome' => (bool) ($this->at_home ?? false),
            'equipment' => $this->equipment,
            'muscles' => $this->muscles,
            'cue' => $this->cue,
            'instructions' => $this->instructions ?? [],
            'videoUrl' => 'https://www.youtube.com/results?search_query='.urlencode($this->name.' exercice technique'),
            // Real last performance of the logged-in user (null = never done yet).
            'lastPerf' => $this->getAttribute('user_last_perf'),
        ];
    }
}
