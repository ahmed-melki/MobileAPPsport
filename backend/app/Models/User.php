<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'first_name',
        'last_name',
        'email',
        'email_verified_at',
        'password',
        'role',
        'city',
        'age',
        'height_cm',
        'bio',
        'sex',
        'main_goal',
        'experience_level',
        'days_per_week',
        'equipment',
        'onboarding_completed_at',
        'sport_level',
        'member_since',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $attributes = [
        'sport_level' => 'beginner',
    ];

    protected $casts = [
        'age' => 'integer',
        'height_cm' => 'integer',
        'days_per_week' => 'integer',
        'onboarding_completed_at' => 'datetime',
        'email_verified_at' => 'datetime',
        'member_since' => 'date:Y-m-d',
        'password' => 'hashed',
    ];

    public function setExperienceLevelAttribute(?string $value): void
    {
        $this->attributes['experience_level'] = $value;
        if ($value !== null) {
            $this->attributes['sport_level'] = match ($value) {
                'expert' => 'advanced',
                default => $value,
            };
        }
    }

    public function setSportLevelAttribute(?string $value): void
    {
        $this->attributes['sport_level'] = $value;
        if ($value !== null) {
            $this->attributes['experience_level'] = match ($value) {
                'advanced' => 'expert',
                default => $value,
            };
        }
    }

    public function sports(): HasMany
    {
        return $this->hasMany(UserSport::class)->orderBy('id');
    }

    public function goals(): HasMany
    {
        return $this->hasMany(Goal::class)->orderByDesc('is_primary')->orderByDesc('created_at');
    }

    public function measurements(): HasMany
    {
        return $this->hasMany(BodyMeasurement::class)->orderByDesc('measured_at');
    }

    public function sessionLogs(): HasMany
    {
        return $this->hasMany(SessionLog::class)->orderByDesc('date');
    }

    public function userPrograms(): HasMany
    {
        return $this->hasMany(UserProgram::class)->orderByDesc('updated_at');
    }

    public function mealEntries(): HasMany
    {
        return $this->hasMany(MealEntry::class);
    }

    public function nutritionTarget(): \Illuminate\Database\Eloquent\Relations\HasOne
    {
        return $this->hasOne(NutritionTarget::class);
    }

    public function favoriteRecipes(): HasMany
    {
        return $this->hasMany(UserFavoriteRecipe::class);
    }

    public function coachBookings(): HasMany
    {
        return $this->hasMany(CoachBooking::class);
    }

    public function coachAthletes(): HasMany
    {
        return $this->hasMany(CoachAthlete::class);
    }

    public function productFavorites(): HasMany
    {
        return $this->hasMany(Favorite::class);
    }

    public function cart(): \Illuminate\Database\Eloquent\Relations\HasOne
    {
        return $this->hasOne(Cart::class);
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }

    public function emailCodes(): HasMany
    {
        return $this->hasMany(EmailCode::class)->orderByDesc('created_at');
    }

    /**
     * Determine whether the user can access a Filament panel.
     *
     * @param mixed $panel
     * @return bool
     */
    public function canAccessPanel(mixed $panel = null): bool
    {
        return $this->role === 'admin';
    }
}

