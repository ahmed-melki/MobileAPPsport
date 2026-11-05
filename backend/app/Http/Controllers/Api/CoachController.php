<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreCoachBookingRequest;
use App\Http\Resources\CoachAthleteResource;
use App\Http\Resources\CoachAvailabilityResource;
use App\Http\Resources\CoachBookingResource;
use App\Http\Resources\CoachResource;
use App\Models\CoachAvailability;
use App\Models\CoachBooking;
use App\Models\CoachProfile;
use App\Models\CoachAthlete;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CoachController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $coaches = CoachProfile::with('specialties')->when($request->filled('search'), fn ($q) => $q->where('name', 'like', '%'.$request->string('search').'%'))->when($request->filled('specialty'), fn ($q) => $q->whereHas('specialties', fn ($s) => $s->where('specialty', $request->specialty)))->orderBy('name')->get();
        return ApiResponse::success(CoachResource::collection($coaches));
    }

    public function show(string $slug): JsonResponse
    {
        return ApiResponse::success(new CoachResource(CoachProfile::with('specialties')->where('slug', $slug)->firstOrFail()));
    }

    public function availability(string $slug): JsonResponse
    {
        $coach = CoachProfile::where('slug', $slug)->firstOrFail();
        return ApiResponse::success(CoachAvailabilityResource::collection($coach->availabilities()->where('status', 'available')->where('scheduled_at', '>', now())->orderBy('scheduled_at')->get()));
    }

    public function bookings(Request $request): JsonResponse
    {
        return ApiResponse::success(CoachBookingResource::collection($request->user()->coachBookings()->with('coach')->orderByDesc('scheduled_at')->get()));
    }

    public function storeBooking(StoreCoachBookingRequest $request): JsonResponse
    {
        $booking = DB::transaction(function () use ($request) {
            $availability = CoachAvailability::with('coach')->lockForUpdate()->findOrFail($request->availabilityId);
            if ($availability->status !== 'available' || $availability->scheduled_at->isPast()) abort(409, 'Availability is no longer available.');
            $availability->update(['status' => 'booked']);
            return $request->user()->coachBookings()->create(['coach_profile_id' => $availability->coach_profile_id, 'availability_id' => $availability->id, 'scheduled_at' => $availability->scheduled_at, 'type' => $request->type, 'status' => 'pending']);
        });
        return ApiResponse::success(new CoachBookingResource($booking->load('coach')), 'Booking created successfully.', [], 201);
    }

    public function cancel(Request $request, int $booking): JsonResponse
    {
        $record = $request->user()->coachBookings()->with('availability')->find($booking);
        if (! $record) return ApiResponse::error('Unauthorized.', [], 403);
        DB::transaction(function () use ($record) { $record->update(['status' => 'cancelled']); if ($record->availability) $record->availability->update(['status' => 'available']); });
        return ApiResponse::success(new CoachBookingResource($record->fresh('coach')), 'Booking cancelled successfully.');
    }

    public function confirm(Request $request, int $booking): JsonResponse
    {
        $coach = $this->coachFor($request);
        if (! $coach) return ApiResponse::error('Unauthorized.', [], 403);
        $record = CoachBooking::with('availability')->where('coach_profile_id', $coach->id)->findOrFail($booking);
        DB::transaction(function () use ($record, $coach) { $record->update(['status' => 'confirmed']); CoachAthlete::firstOrCreate(['coach_profile_id' => $coach->id, 'user_id' => $record->user_id], ['goal' => null, 'progress' => 0]); });
        return ApiResponse::success(new CoachBookingResource($record->fresh('coach')), 'Booking confirmed successfully.');
    }

    public function decline(Request $request, int $booking): JsonResponse
    {
        $coach = $this->coachFor($request);
        if (! $coach) return ApiResponse::error('Unauthorized.', [], 403);
        $record = CoachBooking::with('availability')->where('coach_profile_id', $coach->id)->findOrFail($booking);
        DB::transaction(function () use ($record) { $record->update(['status' => 'declined']); if ($record->availability) $record->availability->update(['status' => 'available']); });
        return ApiResponse::success(new CoachBookingResource($record->fresh('coach')), 'Booking declined successfully.');
    }

    public function athletes(Request $request): JsonResponse
    {
        $coach = $this->coachFor($request);
        if (! $coach) return ApiResponse::error('Unauthorized.', [], 403);
        return ApiResponse::success(CoachAthleteResource::collection(CoachAthlete::with('user')->where('coach_profile_id', $coach->id)->get()));
    }

    private function coachFor(Request $request): ?CoachProfile
    {
        return $request->user()->role === 'coach' ? CoachProfile::where('user_id', $request->user()->id)->first() : null;
    }
}
