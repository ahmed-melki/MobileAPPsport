<?php

namespace App\Http\Requests;

use App\Support\ExerciseLibrary;
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
            'muscleGroup' => ['nullable', Rule::in(ExerciseLibrary::MUSCLE_GROUPS)],
            'level' => ['nullable', Rule::in(['beginner', 'intermediate', 'expert'])],
            'atHome' => ['nullable', 'boolean'],
            'search' => ['nullable', 'string', 'max:255'],
        ];
    }
}
