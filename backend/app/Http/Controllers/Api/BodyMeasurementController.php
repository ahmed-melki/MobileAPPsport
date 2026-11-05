<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreBodyMeasurementRequest;
use App\Http\Resources\BodyMeasurementResource;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BodyMeasurementController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $measurements = $request->user()->measurements()->get();

        return ApiResponse::success(BodyMeasurementResource::collection($measurements));
    }

    public function store(StoreBodyMeasurementRequest $request): JsonResponse
    {
        // One measurement per day: a new entry on the same date updates it
        // (the onboarding already creates today's weight-only measurement).
        $values = ['weight_kg' => $request->input('weightKg')];
        foreach (['chest_cm' => 'chestCm', 'waist_cm' => 'waistCm', 'hips_cm' => 'hipsCm', 'arm_cm' => 'armCm', 'thigh_cm' => 'thighCm'] as $column => $input) {
            if ($request->filled($input)) {
                $values[$column] = $request->input($input);
            }
        }

        $measurement = $request->user()->measurements()->reorder()->whereDate('measured_at', $request->input('date'))->first();
        if ($measurement) {
            $measurement->update($values);
        } else {
            $measurement = $request->user()->measurements()->create($values + ['measured_at' => $request->input('date')]);
        }

        return ApiResponse::success(new BodyMeasurementResource($measurement), 'Measurement created successfully.', [], 201);
    }
}
