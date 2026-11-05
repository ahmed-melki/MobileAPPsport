<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class FoodResource extends JsonResource
{
    public function toArray($request): array
    {
        return ['id' => $this->slug, 'name' => $this->name, 'category' => $this->category, 'serving' => $this->serving, 'calories' => (int) $this->calories, 'protein' => (float) $this->protein, 'carbs' => (float) $this->carbs, 'fat' => (float) $this->fat];
    }
}
