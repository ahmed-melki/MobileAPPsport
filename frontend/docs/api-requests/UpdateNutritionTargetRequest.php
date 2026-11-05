<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateNutritionTargetRequest extends FormRequest
{
    public function authorize(): bool { return true; }
    public function rules(): array
    {
        return ['calories' => ['required', 'integer', 'min:0'], 'protein' => ['required', 'numeric', 'min:0'], 'carbs' => ['required', 'numeric', 'min:0'], 'fat' => ['required', 'numeric', 'min:0']];
    }
}
