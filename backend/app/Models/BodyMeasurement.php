<?php

namespace App\Models;

use Database\Factories\BodyMeasurementFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BodyMeasurement extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'measured_at',
        'weight_kg',
        'chest_cm',
        'waist_cm',
        'hips_cm',
        'arm_cm',
        'thigh_cm',
    ];

    protected $casts = [
        'measured_at' => 'date:Y-m-d',
        'weight_kg' => 'float',
        'chest_cm' => 'float',
        'waist_cm' => 'float',
        'hips_cm' => 'float',
        'arm_cm' => 'float',
        'thigh_cm' => 'float',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
