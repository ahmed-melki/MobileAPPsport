<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CoachSpecialty extends Model
{
    public $timestamps = false;
    protected $fillable = ['coach_profile_id', 'specialty'];
    public function coach(): BelongsTo { return $this->belongsTo(CoachProfile::class, 'coach_profile_id'); }
}
