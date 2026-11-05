<?php

namespace App\Http\Requests;

use App\Support\TunisianGovernorates;
use Illuminate\Foundation\Http\FormRequest;

class StoreOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        // Support nested shipping object if provided
        if ($this->has('shipping') && is_array($this->shipping)) {
            $shipping = $this->shipping;
            $merge = [];
            if (! $this->has('fullName') && isset($shipping['fullName'])) $merge['fullName'] = $shipping['fullName'];
            if (! $this->has('fullName') && isset($shipping['name'])) $merge['fullName'] = $shipping['name'];
            if (! $this->has('phone') && isset($shipping['phone'])) $merge['phone'] = $shipping['phone'];
            if (! $this->has('addressLine1') && isset($shipping['addressLine1'])) $merge['addressLine1'] = $shipping['addressLine1'];
            if (! $this->has('addressLine1') && isset($shipping['address'])) $merge['addressLine1'] = $shipping['address'];
            if (! $this->has('addressLine2') && array_key_exists('addressLine2', $shipping)) $merge['addressLine2'] = $shipping['addressLine2'];
            if (! $this->has('city') && isset($shipping['city'])) $merge['city'] = $shipping['city'];
            if (! $this->has('governorate') && isset($shipping['governorate'])) $merge['governorate'] = $shipping['governorate'];
            if (! $this->has('postalCode') && isset($shipping['postalCode'])) $merge['postalCode'] = $shipping['postalCode'];
            if (! $this->has('notes') && array_key_exists('notes', $shipping)) $merge['notes'] = $shipping['notes'];
            if (! empty($merge)) {
                $this->merge($merge);
            }
        }
    }

    public function rules(): array
    {
        return [
            'fullName' => ['required', 'string', 'max:255'],
            'phone' => ['required', 'string', 'regex:/^(\+216)?[0-9]{8}$/'],
            'addressLine1' => ['required', 'string', 'max:255'],
            'addressLine2' => ['nullable', 'string', 'max:255'],
            'city' => ['required', 'string', 'max:255'],
            'governorate' => [
                'required',
                'string',
                function ($attribute, $value, $fail) {
                    if (! TunisianGovernorates::isValid($value)) {
                        $fail('The selected governorate is invalid. Must be one of the 24 Tunisian governorates.');
                    }
                },
            ],
            'postalCode' => ['required', 'string', 'max:20'],
            'notes' => ['nullable', 'string', 'max:1000'],
            'paymentMethod' => ['required', 'string', 'in:cash_on_delivery'],
        ];
    }
}
