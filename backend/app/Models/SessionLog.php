<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class SessionLog extends Model
{
    protected $table = 'session_logs';

    protected $fillable = [
        'user_id',
        'session_slug',
        'program_slug',
        'session_title',
        'program_title',
        'completed_at',
        'date',
        'duration_min',
        'highlight',
    ];

    protected $casts = [
        'completed_at' => 'datetime',
        'date' => 'date:Y-m-d',
        'duration_min' => 'integer',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function sets(): HasMany
    {
        return $this->hasMany(SessionLogSet::class);
    }
}
