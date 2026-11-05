<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreOnboardingRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'sex' => ['required', Rule::in(['male', 'female', 'other'])],
            'age' => ['required', 'integer', 'min:14', 'max:90'],
            'heightCm' => ['required', 'integer', 'min:120', 'max:230'],
            'weightKg' => ['required', 'numeric', 'min:30', 'max:300'],
            'mainGoal' => ['required', Rule::in(['lose_weight', 'gain_muscle', 'clean_bulk', 'maintain', 'endurance'])],
            'experienceLevel' => ['required', Rule::in(['beginner', 'intermediate', 'expert'])],
            'daysPerWeek' => ['required', 'integer', 'min:2', 'max:6'],
            'equipment' => ['required', Rule::in(['gym', 'home', 'none'])],
        ];
    }
}
