<?php

namespace App\Support;

use Illuminate\Http\JsonResponse;
use Illuminate\Validation\ValidationException;

class ApiResponse
{
    public static function success(mixed $data = null, string $message = 'Success', array $meta = [], int $status = 200): JsonResponse
    {
        return response()->json([
            'data' => $data,
            'meta' => $meta ?: new \stdClass(),
            'message' => $message,
        ], $status);
    }

    public static function error(string $message = 'Something went wrong.', array $errors = [], int $status = 400): JsonResponse
    {
        $payload = [
            'message' => $message,
        ];

        if ($errors !== []) {
            $payload['errors'] = $errors;
        }

        return response()->json($payload, $status);
    }

    public static function validation(ValidationException $exception): JsonResponse
    {
        return self::error($exception->getMessage(), $exception->errors(), 422);
    }
}
