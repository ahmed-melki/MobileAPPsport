<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\UpdateProfileRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Models\UserSport;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProfileController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        return ApiResponse::success(new UserResource($request->user()->load('sports')));
    }

    public function update(UpdateProfileRequest $request): JsonResponse
    {
        $user = $request->user();

        $attributes = array_filter([
            'first_name' => $request->input('firstName'),
            'last_name' => $request->input('lastName'),
            'city' => $request->input('city'),
            'age' => $request->input('age'),
            'height_cm' => $request->input('heightCm'),
            'bio' => $request->input('bio'),
        ], fn ($value) => ! is_null($value));

        $user->fill($attributes);

        // Level: "level" (beginner|intermediate|advanced) wins over "experienceLevel".
        // Before, both were applied and the old experienceLevel overwrote the new level,
        // so the level never changed (bug seen on the admin account).
        if ($request->filled('level')) {
            $user->sport_level = $request->input('level');
        } elseif ($request->filled('experienceLevel')) {
            $user->experience_level = $request->input('experienceLevel');
        }

        $user->save();

        if ($request->has('sports')) {
            $this->syncSports($user, $request->input('sports', []));
        }

        return ApiResponse::success(new UserResource($user->fresh(['sports'])));
    }

    protected function syncSports(User $user, array $sports): void
    {
        $user->sports()->delete();

        foreach (array_unique($sports) as $sport) {
            $user->sports()->create([
                'sport_key' => $sport,
            ]);
        }
    }
}
