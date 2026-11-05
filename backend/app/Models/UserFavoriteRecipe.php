<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserFavoriteRecipe extends Model
{
    protected $fillable = ['user_id', 'recipe_slug'];
    public function recipe(): BelongsTo { return $this->belongsTo(Recipe::class, 'recipe_slug', 'slug'); }
}
