<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreMealRequest extends FormRequest
{
    public function authorize(): bool { return true; }
    public function rules(): array
    {
        return ['date' => ['required', 'date_format:Y-m-d'], 'type' => ['required', Rule::in(['breakfast', 'lunch', 'snack', 'dinner'])], 'name' => ['required', 'string', 'max:255'], 'time' => ['required', 'date_format:H:i'], 'foodId' => ['nullable', 'string'], 'recipeId' => ['nullable', 'string'], 'calories' => ['required', 'integer', 'min:0'], 'protein' => ['required', 'numeric', 'min:0'], 'carbs' => ['required', 'numeric', 'min:0'], 'fat' => ['required', 'numeric', 'min:0']];
    }
}
