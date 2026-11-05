<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class NutritionTargetResource extends JsonResource
{
    public function toArray($request): array
    {
        return ['id' => $this->id, 'calories' => (int) $this->calories, 'protein' => (float) $this->protein, 'carbs' => (float) $this->carbs, 'fat' => (float) $this->fat];
    }
}
