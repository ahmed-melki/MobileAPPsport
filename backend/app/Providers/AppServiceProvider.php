<?php

namespace App\Providers;

use App\Support\ApiResponse;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Str;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        RateLimiter::for('auth-codes', function (Request $request) {
            $email = Str::lower((string) $request->input('email', ''));
            $ip = (string) $request->ip();

            return Limit::perMinute(10)->by($email.'|'.$ip)->response(function () {
                return ApiResponse::error('Too many requests. Please try again later.', [
                    'email' => ['Too many requests. Please try again later.'],
                ], 429);
            });
        });
    }
}
