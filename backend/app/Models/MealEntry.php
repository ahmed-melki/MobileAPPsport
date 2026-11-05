<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MealEntry extends Model
{
    protected $fillable = ['user_id', 'food_id', 'recipe_slug', 'date', 'type', 'name', 'time', 'calories', 'protein', 'carbs', 'fat'];
    protected $casts = ['date' => 'date:Y-m-d', 'calories' => 'integer', 'protein' => 'float', 'carbs' => 'float', 'fat' => 'float'];
    public function user(): BelongsTo { return $this->belongsTo(User::class); }
    public function food(): BelongsTo { return $this->belongsTo(Food::class, 'food_id', 'slug'); }
}
