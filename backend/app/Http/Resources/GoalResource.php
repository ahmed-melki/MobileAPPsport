<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class GoalResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'kind' => $this->kind,
            'detail' => $this->detail,
            'target' => $this->target,
            'deadline' => $this->deadline?->format('Y-m-d'),
            'progress' => (float) $this->progress,
            'active' => (bool) $this->is_active,
            'primary' => (bool) $this->is_primary,
        ];
    }
}
