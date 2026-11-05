<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;

/**
 * @extends Factory<User>
 */
class UserFactory extends Factory
{
    protected static ?string $password;

    public function definition(): array
    {
        return [
            'first_name' => fake()->firstName(),
            'last_name' => fake()->lastName(),
            'email' => fake()->unique()->safeEmail(),
            'email_verified_at' => now(),
            'password' => static::$password ??= Hash::make('password'),
            'role' => 'member',
            'city' => fake()->city(),
            'age' => fake()->numberBetween(18, 50),
            'height_cm' => fake()->numberBetween(150, 200),
            'bio' => fake()->sentence(),
            'sport_level' => fake()->randomElement(['beginner', 'intermediate', 'advanced']),
            'member_since' => fake()->dateTimeBetween('-5 years', 'now')->format('Y-m-d'),
        ];
    }

    public function unverified(): static
    {
        return $this->state(fn (array $attributes) => [
            'email_verified_at' => null,
        ]);
    }
}
