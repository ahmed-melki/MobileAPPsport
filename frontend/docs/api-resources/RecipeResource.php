<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class RecipeResource extends JsonResource
{
    public function toArray($request): array
    {
        return ['id' => $this->slug, 'name' => $this->name, 'subtitle' => $this->subtitle, 'calories' => (int) $this->calories, 'protein' => (float) $this->protein, 'duration' => (int) $this->duration, 'icon' => $this->icon_key, 'accent' => $this->accent_key];
    }
}
