<?php

namespace Database\Factories;

use App\Models\UserSport;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<UserSport>
 */
class UserSportFactory extends Factory
{
    protected $model = UserSport::class;

    public function definition(): array
    {
        return [
            'sport_key' => fake()->randomElement(['Hyrox', 'Force', 'Course', 'Natation', 'Boxe', 'Yoga']),
        ];
    }
}
