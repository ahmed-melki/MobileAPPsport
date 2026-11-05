<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserProgram extends Model
{
    protected $table = 'user_programs';

    protected $fillable = [
        'user_id',
        'program_slug',
        'status',
        'started_at',
        'paused_at',
    ];

    protected $casts = [
        'started_at' => 'datetime',
        'paused_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function program(): BelongsTo
    {
        return $this->belongsTo(TrainingProgram::class, 'program_slug', 'slug');
    }
}
