<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class NutritionTarget extends Model
{
    protected $fillable = ['user_id', 'calories', 'protein', 'carbs', 'fat'];
    protected $casts = ['calories' => 'integer', 'protein' => 'float', 'carbs' => 'float', 'fat' => 'float'];
    public function user(): BelongsTo { return $this->belongsTo(User::class); }
}
