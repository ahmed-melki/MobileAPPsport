<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ExerciseIndexRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'page' => ['nullable', 'integer', 'min:1'],
            'category' => ['nullable', Rule::in(['strength', 'olympic', 'hyrox', 'cardio', 'mobility', 'core'])],
            'search' => ['nullable', 'string', 'max:255'],
        ];
    }
}
