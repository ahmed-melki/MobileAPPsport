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
            'equipment' => $this->equipment,
            'muscles' => $this->muscles,
            'cue' => $this->cue,
            'lastPerf' => $this->last_perf,
        ];
    }
}
