<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SessionLogSet extends Model
{
    protected $table = 'session_log_sets';

    protected $fillable = [
        'session_log_id',
        'exercise_slug',
        'set_number',
        'reps',
        'load_kg',
        'kind',
        'unit_note',
    ];

    protected $casts = [
        'reps' => 'integer',
        'set_number' => 'integer',
        'load_kg' => 'float',
    ];

    public function sessionLog(): BelongsTo
    {
        return $this->belongsTo(SessionLog::class);
    }

    public function exercise(): BelongsTo
    {
        return $this->belongsTo(Exercise::class, 'exercise_slug', 'slug');
    }
}
