<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CoachAthlete extends Model
{
    protected $fillable = ['coach_profile_id', 'user_id', 'goal', 'progress', 'last_session_at'];
    protected $casts = ['progress' => 'float', 'last_session_at' => 'datetime'];
    public function coach(): BelongsTo { return $this->belongsTo(CoachProfile::class, 'coach_profile_id'); }
    public function user(): BelongsTo { return $this->belongsTo(User::class); }
}
