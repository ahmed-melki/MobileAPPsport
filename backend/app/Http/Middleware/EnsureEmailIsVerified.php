<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class EnsureEmailIsVerified
{
    public function handle(Request $request, Closure $next): mixed
    {
        $user = $request->user();

        if ($user && ! $user->hasVerifiedEmail()) {
            if ($this->isExempt($request)) {
                return $next($request);
            }

            return response()->json([
                'code' => 'email_not_verified',
                'message' => 'Your email address is not verified.',
            ], 403);
        }

        return $next($request);
    }

    private function isExempt(Request $request): bool
    {
        if ($request->isMethod('GET') && ($request->is('api/me') || $request->is('me'))) {
            return true;
        }

        if ($request->is('*/logout') || $request->is('logout')) {
            return true;
        }

        if ($request->is('*/verify-email') || $request->is('verify-email')) {
            return true;
        }

        if ($request->is('*/resend-code') || $request->is('resend-code')) {
            return true;
        }

        return false;
    }
}
