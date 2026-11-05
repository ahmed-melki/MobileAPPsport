<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CoachAvailability extends Model
{
    public $timestamps = false;
    protected $fillable = ['coach_profile_id', 'scheduled_at', 'duration_min', 'status'];
    protected $casts = ['scheduled_at' => 'datetime', 'duration_min' => 'integer'];
    public function coach(): BelongsTo { return $this->belongsTo(CoachProfile::class, 'coach_profile_id'); }
}
