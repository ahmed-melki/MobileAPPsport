<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'firstName' => ['sometimes', 'string', 'max:255'],
            'lastName' => ['sometimes', 'string', 'max:255'],
            'city' => ['nullable', 'string', 'max:255'],
            'age' => ['nullable', 'integer', 'min:1', 'max:120'],
            'heightCm' => ['nullable', 'integer', 'min:50', 'max:260'],
            'bio' => ['nullable', 'string', 'max:1000'],
            'level' => ['nullable', Rule::in(['beginner', 'intermediate', 'advanced'])],
            'experienceLevel' => ['nullable', Rule::in(['beginner', 'intermediate', 'expert'])],
            'sports' => ['sometimes', 'nullable', 'array'],
            'sports.*' => ['string', 'max:255'],
        ];
    }
}
