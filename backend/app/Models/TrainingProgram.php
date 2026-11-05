<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class TrainingProgram extends Model
{
    protected $table = 'training_programs';

    protected $primaryKey = 'slug';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'slug',
        'title',
        'subtitle',
        'weeks',
        'days_per_week',
        'level',
        'goal_tags',
        'equipment',
    ];

    protected $casts = [
        'weeks' => 'integer',
        'days_per_week' => 'integer',
        'goal_tags' => 'array',
    ];

    public function sessions(): HasMany
    {
        return $this->hasMany(WorkoutSession::class, 'program_slug', 'slug');
    }
}
