<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'firstName' => $this->first_name,
            'lastName' => $this->last_name,
            'email' => $this->email,
            'emailVerified' => $this->email_verified_at !== null,
            'role' => $this->role,
            'city' => $this->city,
            'age' => $this->age,
            'heightCm' => $this->height_cm,
            'bio' => $this->bio,
            'sex' => $this->sex,
            'mainGoal' => $this->main_goal,
            'experienceLevel' => $this->experience_level,
            'daysPerWeek' => $this->days_per_week,
            'equipment' => $this->equipment,
            'level' => $this->sport_level,
            'onboardingCompleted' => $this->onboarding_completed_at !== null,
            'sports' => $this->whenLoaded('sports', fn () => $this->sports->pluck('sport_key')->values()->all(), $this->sports()->pluck('sport_key')->values()->all()),
            'memberSince' => $this->member_since?->format('Y-m-d'),
        ];
    }
}
