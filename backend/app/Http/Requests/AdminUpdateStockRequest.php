<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class AdminUpdateStockRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        if (! $this->has('stockQuantity')) {
            if ($this->has('quantity')) {
                $this->merge(['stockQuantity' => $this->quantity]);
            } elseif ($this->has('stock')) {
                $this->merge(['stockQuantity' => $this->stock]);
            }
        }
    }

    public function rules(): array
    {
        return [
            'stockQuantity' => ['required', 'integer', 'min:0'],
        ];
    }
}
