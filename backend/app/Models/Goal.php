<?php

namespace App\Models;

use Database\Factories\GoalFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Goal extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'kind',
        'detail',
        'target',
        'deadline',
        'progress',
        'is_active',
        'is_primary',
    ];

    protected $casts = [
        'deadline' => 'date:Y-m-d',
        'progress' => 'float',
        'is_active' => 'boolean',
        'is_primary' => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
