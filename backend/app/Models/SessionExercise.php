<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SessionExercise extends Model
{
    protected $table = 'session_exercises';

    public $timestamps = false;

    protected $fillable = [
        'session_slug',
        'exercise_slug',
        'sets',
        'reps',
        'load_kg',
        'rest_sec',
        'kind',
        'unit_note',
    ];

    protected $casts = [
        'sets' => 'integer',
        'reps' => 'integer',
        'load_kg' => 'float',
        'rest_sec' => 'integer',
    ];

    public function session(): BelongsTo
    {
        return $this->belongsTo(WorkoutSession::class, 'session_slug', 'slug');
    }

    public function exercise(): BelongsTo
    {
        return $this->belongsTo(Exercise::class, 'exercise_slug', 'slug');
    }
}
