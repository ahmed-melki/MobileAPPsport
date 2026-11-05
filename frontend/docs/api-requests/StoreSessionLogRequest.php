<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreSessionLogRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $data = $this->all();

        if (! array_key_exists('sessionId', $data) && array_key_exists('sessionSlug', $data)) {
            $data['sessionId'] = $data['sessionSlug'];
        }

        if (! array_key_exists('programId', $data) && array_key_exists('programSlug', $data)) {
            $data['programId'] = $data['programSlug'];
        }

        if (! array_key_exists('completedAt', $data) && array_key_exists('date', $data)) {
            $data['completedAt'] = $data['date'];
        }

        if (isset($data['sets']) && is_array($data['sets'])) {
            foreach ($data['sets'] as $index => $set) {
                if (! is_array($set)) {
                    continue;
                }

                if (! array_key_exists('exerciseId', $set) && array_key_exists('exerciseSlug', $set)) {
                    $data['sets'][$index]['exerciseId'] = $set['exerciseSlug'];
                }

                if (! array_key_exists('loadKg', $set) && array_key_exists('load', $set)) {
                    $data['sets'][$index]['loadKg'] = $set['load'];
                }

                if (! array_key_exists('setNumber', $set) && array_key_exists('set', $set)) {
                    $data['sets'][$index]['setNumber'] = $set['set'];
                }
            }
        }

        if (isset($data['completedAt']) && is_string($data['completedAt'])
            && preg_match('/^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})\.\d+Z$/', $data['completedAt'], $m)) {
            $data['completedAt'] = $m[1] . 'Z';
        }

        $this->replace($data);
    }

    public function rules(): array
    {
        return [
            'date' => ['sometimes', 'date_format:Y-m-d'],
            'completedAt' => ['required_without:date', 'date_format:Y-m-d\TH:i:s\Z'],
            'sessionId' => ['required', 'string'],
            'sessionTitle' => ['sometimes', 'string'],
            'programId' => ['nullable', 'string'],
            'programTitle' => ['sometimes', 'string'],
            'durationMin' => ['required', 'integer', 'min:1'],
            'highlight' => ['nullable', 'string'],
            'sets' => ['required', 'array'],
            'sets.*.exerciseId' => ['required', 'string'],
            'sets.*.setNumber' => ['required', 'integer', 'min:1'],
            'sets.*.reps' => ['required', 'integer', 'min:1'],
            'sets.*.loadKg' => ['nullable', 'numeric', 'min:0'],
            'sets.*.kind' => ['required', Rule::in(['load', 'distance', 'bodyweight'])],
            'sets.*.unitNote' => ['nullable', 'string'],
        ];
    }
}
