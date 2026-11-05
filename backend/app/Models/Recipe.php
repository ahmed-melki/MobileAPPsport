<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Recipe extends Model
{
    protected $table = 'recipes';
    protected $primaryKey = 'slug';
    public $incrementing = false;
    protected $keyType = 'string';
    public $timestamps = false;
    protected $fillable = ['slug', 'name', 'subtitle', 'calories', 'protein', 'carbs', 'fat', 'duration', 'meal_type', 'goal_tags', 'ingredients', 'steps', 'is_tunisian', 'icon_key', 'accent_key'];
    protected $casts = ['calories' => 'integer', 'protein' => 'float', 'carbs' => 'float', 'fat' => 'float', 'duration' => 'integer', 'goal_tags' => 'array', 'ingredients' => 'array', 'steps' => 'array', 'is_tunisian' => 'boolean'];
}
