<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class AdminUpdateOrderStatusRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'status' => ['required', 'string', 'in:confirmed,shipped,delivered,cancelled'],
            'comment' => ['nullable', 'string', 'max:1000'],
        ];
    }
}
