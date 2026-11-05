<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateGoalRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'kind' => ['sometimes', Rule::in(['mass_gain', 'weight_loss', 'endurance', 'fitness'])],
            'detail' => ['sometimes', 'string', 'max:1000'],
            'target' => ['sometimes', 'string', 'max:255'],
            'deadline' => ['nullable', 'date_format:Y-m-d'],
            'progress' => ['sometimes', 'numeric', 'min:0', 'max:1'],
            'active' => ['sometimes', 'boolean'],
            'primary' => ['sometimes', 'boolean'],
        ];
    }
}
