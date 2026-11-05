<?php

namespace Database\Factories;

use App\Models\BodyMeasurement;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<BodyMeasurement>
 */
class BodyMeasurementFactory extends Factory
{
    protected $model = BodyMeasurement::class;

    public function definition(): array
    {
        return [
            'measured_at' => now()->subDays(fake()->numberBetween(1, 30))->format('Y-m-d'),
            'weight_kg' => fake()->randomFloat(2, 60, 90),
            'chest_cm' => fake()->randomFloat(2, 80, 100),
            'waist_cm' => fake()->randomFloat(2, 65, 90),
            'hips_cm' => fake()->randomFloat(2, 90, 110),
            'arm_cm' => fake()->randomFloat(2, 25, 35),
            'thigh_cm' => fake()->randomFloat(2, 45, 65),
        ];
    }
}
