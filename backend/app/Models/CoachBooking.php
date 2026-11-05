<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CoachBooking extends Model
{
    protected $fillable = ['user_id', 'coach_profile_id', 'availability_id', 'scheduled_at', 'type', 'status'];
    protected $casts = ['scheduled_at' => 'datetime'];
    public function user(): BelongsTo { return $this->belongsTo(User::class); }
    public function coach(): BelongsTo { return $this->belongsTo(CoachProfile::class, 'coach_profile_id'); }
    public function availability(): BelongsTo { return $this->belongsTo(CoachAvailability::class, 'availability_id'); }
}
