<?php

namespace App\Http\Requests;

use App\Models\Product;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class AdminUpdateProductRequest extends FormRequest
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
        $slug = $this->route('slug');
        $productId = Product::withTrashed()->where('slug', $slug)->value('id');

        return [
            'name' => ['sometimes', 'string', 'max:255'],
            'slug' => ['sometimes', 'string', 'max:255', Rule::unique('products', 'slug')->ignore($productId)],
            'brand' => ['sometimes', 'string', 'max:255'],
            'category' => ['sometimes', 'string', 'max:255'],
            'price' => ['sometimes', 'numeric', 'min:0'],
            'description' => ['sometimes', 'string'],
            'features' => ['nullable', 'array'],
            'features.*' => ['string'],
            'colorKey' => ['sometimes', 'string', 'max:255'],
            'iconKey' => ['sometimes', 'string', 'max:255'],
            'badgeKey' => ['nullable', 'string', 'max:255'],
            'stockQuantity' => ['sometimes', 'integer', 'min:0'],
            'rating' => ['prohibited'],
            'reviewCount' => ['prohibited'],
            'review_count' => ['prohibited'],
        ];
    }
}
