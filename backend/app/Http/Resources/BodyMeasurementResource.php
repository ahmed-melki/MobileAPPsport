<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class BodyMeasurementResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'date' => $this->measured_at?->format('Y-m-d'),
            'weightKg' => (float) $this->weight_kg,
            'chestCm' => $this->chest_cm !== null ? (float) $this->chest_cm : null,
            'waistCm' => $this->waist_cm !== null ? (float) $this->waist_cm : null,
            'hipsCm' => $this->hips_cm !== null ? (float) $this->hips_cm : null,
            'armCm' => $this->arm_cm !== null ? (float) $this->arm_cm : null,
            'thighCm' => $this->thigh_cm !== null ? (float) $this->thigh_cm : null,
        ];
    }
}
