<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreCoachBookingRequest extends FormRequest
{
    public function authorize(): bool { return true; }
    public function rules(): array
    {
        return ['availabilityId' => ['required', 'integer', 'exists:coach_availabilities,id'], 'type' => ['required', 'string', 'max:255']];
    }
}
