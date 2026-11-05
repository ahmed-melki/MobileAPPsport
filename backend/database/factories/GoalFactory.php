<?php

namespace Database\Factories;

use App\Models\Goal;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Goal>
 */
class GoalFactory extends Factory
{
    protected $model = Goal::class;

    public function definition(): array
    {
        return [
            'kind' => fake()->randomElement(['mass_gain', 'weight_loss', 'endurance', 'fitness']),
            'detail' => fake()->sentence(),
            'target' => '10 km < 50 min',
            'deadline' => now()->addMonth()->format('Y-m-d'),
            'progress' => fake()->randomFloat(2, 0, 1),
            'is_active' => true,
            'is_primary' => false,
        ];
    }
}
