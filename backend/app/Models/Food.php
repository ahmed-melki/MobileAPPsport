<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Food extends Model
{
    protected $table = 'foods';
    protected $primaryKey = 'slug';
    public $incrementing = false;
    protected $keyType = 'string';
    public $timestamps = false;
    protected $fillable = ['slug', 'name', 'category', 'serving', 'calories', 'protein', 'carbs', 'fat', 'is_tunisian'];
    protected $casts = ['calories' => 'integer', 'protein' => 'float', 'carbs' => 'float', 'fat' => 'float', 'is_tunisian' => 'boolean'];
}
