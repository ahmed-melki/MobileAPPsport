<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class AdminStoreProductRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $merge = [];
        if (! $this->has('colorKey') && $this->has('color')) {
            $merge['colorKey'] = $this->color;
        }
        if (! $this->has('iconKey') && $this->has('icon')) {
            $merge['iconKey'] = $this->icon;
        }
        if (! $this->has('badgeKey') && $this->has('badge')) {
            $merge['badgeKey'] = $this->badge;
        }
        if (! $this->has('stockQuantity') && $this->has('stock')) {
            $merge['stockQuantity'] = $this->stock;
        }
        if (! empty($merge)) {
            $this->merge($merge);
        }
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'slug' => ['nullable', 'string', 'max:255', 'unique:products,slug'],
            'brand' => ['required', 'string', 'max:255'],
            'category' => ['required', 'string', 'max:255'],
            'price' => ['required', 'numeric', 'min:0'],
            'description' => ['required', 'string'],
            'features' => ['nullable', 'array'],
            'features.*' => ['string'],
            'colorKey' => ['required', 'string', 'max:255'],
            'iconKey' => ['required', 'string', 'max:255'],
            'badgeKey' => ['nullable', 'string', 'max:255'],
            'stockQuantity' => ['required', 'integer', 'min:0'],
            'rating' => ['prohibited'],
            'reviewCount' => ['prohibited'],
            'review_count' => ['prohibited'],
        ];
    }
}
