<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class MealEntryResource extends JsonResource
{
    public function toArray($request): array
    {
        return ['id' => $this->id, 'date' => $this->date?->format('Y-m-d'), 'type' => $this->type, 'name' => $this->name, 'time' => $this->time, 'calories' => (int) $this->calories, 'protein' => (float) $this->protein, 'carbs' => (float) $this->carbs, 'fat' => (float) $this->fat];
    }
}
