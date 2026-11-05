<?php

namespace App\Support;

class TunisianGovernorates
{
    public const ALL = [
        'Ariana',
        'Béja',
        'Ben Arous',
        'Bizerte',
        'Gabès',
        'Gafsa',
        'Jendouba',
        'Kairouan',
        'Kasserine',
        'Kébili',
        'Le Kef',
        'Mahdia',
        'La Manouba',
        'Médenine',
        'Monastir',
        'Nabeul',
        'Sfax',
        'Sidi Bouzid',
        'Siliana',
        'Sousse',
        'Tataouine',
        'Tozeur',
        'Tunis',
        'Zaghouan',
    ];

    public static function all(): array
    {
        return self::ALL;
    }

    public static function isValid(mixed $governorate): bool
    {
        if (! is_string($governorate) || trim($governorate) === '') {
            return false;
        }

        $normalizedInput = self::normalize($governorate);
        foreach (self::ALL as $gov) {
            if (self::normalize($gov) === $normalizedInput) {
                return true;
            }
        }

        return false;
    }

    public static function canonical(string $governorate): ?string
    {
        $normalizedInput = self::normalize($governorate);
        foreach (self::ALL as $gov) {
            if (self::normalize($gov) === $normalizedInput) {
                return $gov;
            }
        }

        return null;
    }

    public static function normalize(string $value): string
    {
        $value = trim($value);
        $unaccented = iconv('UTF-8', 'ASCII//TRANSLIT//IGNORE', $value);
        if ($unaccented !== false) {
            $value = $unaccented;
        }
        $value = strtolower($value);
        $value = preg_replace('/^(le|la)\s+/i', '', $value);
        $value = preg_replace('/[^a-z0-9]/', '', $value);

        return $value;
    }
}
