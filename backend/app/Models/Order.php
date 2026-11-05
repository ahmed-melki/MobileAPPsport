<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Order extends Model
{
    protected $fillable = [
        'user_id',
        'order_number',
        'subtotal',
        'shipping',
        'total',
        'currency',
        'status',
        'payment_status',
        'payment_method',
        'paid_at',
        'shipping_address',
        'notes',
    ];

    protected $casts = [
        'subtotal' => 'float',
        'shipping' => 'float',
        'total' => 'float',
        'shipping_address' => 'array',
        'paid_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    public function statusHistories(): HasMany
    {
        return $this->hasMany(OrderStatusHistory::class)->orderBy('id');
    }
}
