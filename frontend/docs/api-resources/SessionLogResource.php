<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class SessionLogResource extends JsonResource
{
    public function toArray($request): array
    {
        $volume = 0;

        foreach ($this->sets as $set) {
            if ($set->kind !== 'load') {
                continue;
            }

            $volume += ((float) ($set->load_kg ?? 0)) * (int) ($set->reps ?? 0);
        }

        $completedAt = $this->completed_at ?? $this->date;

        return [
            'id' => $this->id,
            'sessionId' => $this->session_slug,
            'programId' => $this->program_slug,
            'completedAt' => $completedAt?->utc()->format('Y-m-d\TH:i:s\Z'),
            'date' => $completedAt?->format('Y-m-d'),
            'sessionTitle' => $this->session_title,
            'programTitle' => $this->program_title,
            'durationMin' => (int) $this->duration_min,
            'highlight' => $this->highlight,
            'volumeKg' => (int) round($volume),
        ];
    }
}
