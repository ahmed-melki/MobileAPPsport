<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class RecommendedProgramResource extends JsonResource
{
    public function toArray($request): array
    {
        $program = $this->resource['program'];

        return array_merge(
            (new TrainingProgramResource($program))->toArray($request),
            [
                'score' => (int) $this->resource['score'],
                'reasons' => array_values($this->resource['reasons']),
            ],
        );
    }
}
