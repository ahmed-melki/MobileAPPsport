<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Product extends Model
{
    use SoftDeletes;

    protected $fillable = ['slug', 'name', 'brand', 'category', 'price', 'description', 'features', 'rating', 'review_count', 'color_key', 'icon_key', 'badge_key', 'stock_quantity'];
    protected $casts = ['price' => 'float', 'features' => 'array', 'rating' => 'float', 'stock_quantity' => 'integer'];
    public function reviews(): HasMany { return $this->hasMany(ProductReview::class); }
    public function favorites(): HasMany { return $this->hasMany(Favorite::class); }
}
