<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class RecipeResource extends JsonResource
{
    public function toArray($request): array
    {
        return ['id' => $this->slug, 'name' => $this->name, 'subtitle' => $this->subtitle, 'calories' => (int) $this->calories, 'protein' => (float) $this->protein, 'carbs' => (float) ($this->carbs ?? 0), 'fat' => (float) ($this->fat ?? 0), 'duration' => (int) $this->duration, 'mealType' => $this->meal_type, 'goalTags' => $this->goal_tags ?? [], 'ingredients' => $this->ingredients ?? [], 'steps' => $this->steps ?? [], 'isTunisian' => (bool) ($this->is_tunisian ?? false), 'icon' => $this->icon_key, 'accent' => $this->accent_key];
    }
}
