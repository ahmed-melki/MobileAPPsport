<?php

namespace App\Support;

use App\Models\EmailCode;
use App\Models\User;

class EmailCodeService
{
    public const TYPE_VERIFY = 'verify';
    public const TYPE_RESET = 'reset';
    public const MAX_ATTEMPTS = 5;
    public const EXPIRATION_MINUTES = 15;
    public const COOLDOWN_SECONDS = 60;

    /**
     * Check if a new code can be generated (cooldown check).
     */
    public static function isThrottled(User $user, string $type): bool
    {
        $latest = EmailCode::query()
            ->where('user_id', $user->id)
            ->where('type', $type)
            ->latest()
            ->first();

        if (! $latest) {
            return false;
        }

        return $latest->created_at->gt(now()->subSeconds(self::COOLDOWN_SECONDS));
    }

    /**
     * Seconds remaining before next code can be requested.
     */
    public static function cooldownRemainingSeconds(User $user, string $type): int
    {
        $latest = EmailCode::query()
            ->where('user_id', $user->id)
            ->where('type', $type)
            ->latest()
            ->first();

        if (! $latest) {
            return 0;
        }

        $elapsed = $latest->created_at->diffInSeconds(now());

        return max(0, self::COOLDOWN_SECONDS - $elapsed);
    }

    /**
     * Generate and persist a new 6-digit code for the user and type.
     * Older unused codes of the same type are marked as used.
     */
    public static function createCode(User $user, string $type): string
    {
        // Invalidate older unused codes of the same type so only the latest works
        EmailCode::query()
            ->where('user_id', $user->id)
            ->where('type', $type)
            ->whereNull('used_at')
            ->update(['used_at' => now()]);

        $code = (string) random_int(100000, 999999);
        $codeHash = self::hashCode($code);

        EmailCode::create([
            'user_id' => $user->id,
            'type' => $type,
            'code_hash' => $codeHash,
            'expires_at' => now()->addMinutes(self::EXPIRATION_MINUTES),
            'attempts' => 0,
            'used_at' => null,
        ]);

        return $code;
    }

    /**
     * Verify a 6-digit code.
     *
     * @return array{valid: bool, error?: string, message: string, record?: EmailCode}
     */
    public static function verifyCode(User $user, string $type, string $code): array
    {
        $record = EmailCode::query()
            ->where('user_id', $user->id)
            ->where('type', $type)
            ->whereNull('used_at')
            ->latest()
            ->first();

        if (! $record) {
            return [
                'valid' => false,
                'error' => 'invalid_code',
                'message' => 'Le code est invalide ou inexistant.',
            ];
        }

        if ($record->attempts >= self::MAX_ATTEMPTS) {
            return [
                'valid' => false,
                'error' => 'max_attempts',
                'message' => 'Nombre maximal de tentatives atteint. Veuillez demander un nouveau code.',
            ];
        }

        if ($record->isExpired()) {
            return [
                'valid' => false,
                'error' => 'expired',
                'message' => 'Ce code a expiré. Veuillez en demander un nouveau.',
            ];
        }

        $expectedHash = self::hashCode($code);

        if (! hash_equals($record->code_hash, $expectedHash)) {
            $record->increment('attempts');

            if ($record->attempts >= self::MAX_ATTEMPTS) {
                return [
                    'valid' => false,
                    'error' => 'max_attempts',
                    'message' => 'Nombre maximal de tentatives atteint. Veuillez demander un nouveau code.',
                ];
            }

            return [
                'valid' => false,
                'error' => 'invalid_code',
                'message' => 'Le code est invalide.',
            ];
        }

        $record->update(['used_at' => now()]);

        return [
            'valid' => true,
            'message' => 'Code vérifié avec succès.',
            'record' => $record,
        ];
    }

    public static function hashCode(string $code): string
    {
        $key = (string) config('app.key');

        return hash_hmac('sha256', $code, $key);
    }
}
