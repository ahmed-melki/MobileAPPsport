<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class WorkoutSession extends Model
{
    protected $table = 'workout_sessions';

    protected $primaryKey = 'slug';

    public $incrementing = false;

    protected $keyType = 'string';

    public $timestamps = false;

    protected $fillable = [
        'slug',
        'program_slug',
        'title',
        'duration_min',
        'focus',
    ];

    public function program(): BelongsTo
    {
        return $this->belongsTo(TrainingProgram::class, 'program_slug', 'slug');
    }

    public function exercises(): HasMany
    {
        return $this->hasMany(SessionExercise::class, 'session_slug', 'slug');
    }
}
