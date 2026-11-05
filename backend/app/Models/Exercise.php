<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Exercise extends Model
{
    protected $table = 'exercises';

    protected $primaryKey = 'slug';

    public $incrementing = false;

    protected $keyType = 'string';

    public $timestamps = false;

    protected $fillable = [
        'slug',
        'name',
        'category',
        'muscle_group',
        'level',
        'kind',
        'at_home',
        'equipment',
        'muscles',
        'cue',
        'instructions',
        'last_perf',
    ];

    protected $casts = [
        'last_perf' => 'string',
        'at_home' => 'boolean',
        'instructions' => 'array',
    ];
}
