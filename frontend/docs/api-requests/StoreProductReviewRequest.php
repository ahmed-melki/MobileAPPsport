<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreProductReviewRequest extends FormRequest
{
    public function authorize(): bool { return true; }
    public function rules(): array { return ['rating' => ['required', 'numeric', 'min:1', 'max:5'], 'comment' => ['required', 'string', 'max:2000']]; }
}
