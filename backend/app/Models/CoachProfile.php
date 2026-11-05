<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class CoachProfile extends Model
{
    protected $fillable = ['user_id', 'slug', 'name', 'role', 'bio', 'rating', 'review_count', 'sessions', 'price', 'initials', 'accent_key', 'is_online'];
    protected $casts = ['rating' => 'float', 'is_online' => 'boolean'];
    public function user(): BelongsTo { return $this->belongsTo(User::class); }
    public function specialties(): HasMany { return $this->hasMany(CoachSpecialty::class); }
    public function availabilities(): HasMany { return $this->hasMany(CoachAvailability::class); }
}
