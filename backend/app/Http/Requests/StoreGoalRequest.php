<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreGoalRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'kind' => ['required', Rule::in(['mass_gain', 'weight_loss', 'endurance', 'fitness'])],
            'detail' => ['required', 'string', 'max:1000'],
            'target' => ['required', 'string', 'max:255'],
            'deadline' => ['nullable', 'date_format:Y-m-d'],
            'progress' => ['nullable', 'numeric', 'min:0', 'max:1'],
            'active' => ['nullable', 'boolean'],
            'primary' => ['nullable', 'boolean'],
        ];
    }
}
