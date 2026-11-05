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
            'weightKg' => ['required', 'numeric', 'min:0', 'max:500'],
            'chestCm' => ['required', 'numeric', 'min:0', 'max:500'],
            'waistCm' => ['required', 'numeric', 'min:0', 'max:500'],
            'hipsCm' => ['required', 'numeric', 'min:0', 'max:500'],
            'armCm' => ['required', 'numeric', 'min:0', 'max:500'],
            'thighCm' => ['required', 'numeric', 'min:0', 'max:500'],
        ];
    }
}
