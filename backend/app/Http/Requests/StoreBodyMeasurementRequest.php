<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreBodyMeasurementRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'date' => ['required', 'date_format:Y-m-d'],
            'weightKg' => ['required', 'numeric', 'min:30', 'max:300'],
            'chestCm' => ['nullable', 'numeric', 'min:10', 'max:300'],
            'waistCm' => ['nullable', 'numeric', 'min:10', 'max:300'],
            'hipsCm' => ['nullable', 'numeric', 'min:10', 'max:300'],
            'armCm' => ['nullable', 'numeric', 'min:10', 'max:300'],
            'thighCm' => ['nullable', 'numeric', 'min:10', 'max:300'],
        ];
    }
}
