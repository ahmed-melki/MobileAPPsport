<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserSport extends Model
{
    use HasFactory;

    protected $table = 'user_sports';

    public $timestamps = false;

    protected $fillable = [
        'user_id',
        'sport_key',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
