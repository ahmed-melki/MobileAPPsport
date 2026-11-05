<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ChangePasswordRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        if ($this->has('passwordConfirmation')) {
            $this->merge([
                'password_confirmation' => $this->input('passwordConfirmation'),
            ]);
        }
    }

    public function rules(): array
    {
        return [
            'currentPassword' => ['required', 'string'],
            'password' => ['required', 'string', 'min:8', 'different:currentPassword', 'confirmed'],
            'passwordConfirmation' => ['required', 'string'],
        ];
    }
}
