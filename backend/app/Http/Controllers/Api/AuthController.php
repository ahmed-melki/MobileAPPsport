<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\ChangePasswordRequest;
use App\Http\Requests\ForgotPasswordRequest;
use App\Http\Requests\LoginRequest;
use App\Http\Requests\RegisterUserRequest;
use App\Http\Requests\ResendCodeRequest;
use App\Http\Requests\ResetPasswordRequest;
use App\Http\Requests\VerifyEmailRequest;
use App\Http\Resources\UserResource;
use App\Mail\ResetPasswordCodeMail;
use App\Mail\VerificationCodeMail;
use App\Models\User;
use App\Support\ApiResponse;
use App\Support\EmailCodeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

class AuthController extends Controller
{
    public function register(RegisterUserRequest $request): JsonResponse
    {
        $user = User::create([
            'first_name' => $request->input('firstName'),
            'last_name' => $request->input('lastName'),
            'email' => $request->input('email'),
            'password' => $request->input('password'),
            'role' => 'member',
            'member_since' => now()->toDateString(),
        ]);

        $code = EmailCodeService::createCode($user, EmailCodeService::TYPE_VERIFY);
        $emailSent = true;

        try {
            Mail::to($user->email)->send(new VerificationCodeMail($code));
        } catch (\Throwable $e) {
            $emailSent = false;
            Log::error('Failed to send verification email on register: ' . $e->getMessage());
        }

        $token = $user->createToken('apex-api')->plainTextToken;

        return ApiResponse::success([
            'user' => new UserResource($user->load('sports')),
            'token' => $token,
            'emailSent' => $emailSent,
        ], 'User registered successfully.', [], 201);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        if (! Auth::attempt(['email' => $request->email, 'password' => $request->password])) {
            return ApiResponse::error('Invalid credentials.', ['email' => ['The provided credentials are incorrect.']], 401);
        }

        $user = Auth::user();
        $token = $user->createToken('apex-api')->plainTextToken;

        return ApiResponse::success([
            'user' => new UserResource($user->load('sports')),
            'token' => $token,
        ], 'Logged in successfully.');
    }

    public function logout(): JsonResponse
    {
        request()->user()->tokens()->delete();

        return ApiResponse::success(null, 'Logged out successfully.');
    }

    public function verifyEmail(VerifyEmailRequest $request): JsonResponse
    {
        $user = User::where('email', $request->email)->first();

        if (! $user) {
            return ApiResponse::error('Code invalide ou expiré.', ['code' => ['Le code est invalide ou expiré.']], 422);
        }

        if ($user->hasVerifiedEmail()) {
            return ApiResponse::success([
                'user' => new UserResource($user->load('sports')),
            ], 'Email déjà vérifié.');
        }

        $result = EmailCodeService::verifyCode($user, EmailCodeService::TYPE_VERIFY, $request->code);

        if (! $result['valid']) {
            return ApiResponse::error($result['message'], ['code' => [$result['message']]], 422);
        }

        $user->email_verified_at = now();
        $user->save();

        return ApiResponse::success([
            'user' => new UserResource($user->fresh(['sports'])),
        ], 'Email vérifié avec succès.');
    }

    public function resendCode(ResendCodeRequest $request): JsonResponse
    {
        $genericMessage = 'Si un compte non vérifié existe avec cette adresse email, un nouveau code a été envoyé.';
        $user = User::where('email', $request->email)->first();

        if (! $user || $user->hasVerifiedEmail()) {
            return ApiResponse::success(null, $genericMessage);
        }

        if (EmailCodeService::isThrottled($user, EmailCodeService::TYPE_VERIFY)) {
            return ApiResponse::error('Veuillez patienter avant de demander un nouveau code.', [
                'email' => ['Veuillez patienter avant de demander un nouveau code.'],
            ], 429);
        }

        $code = EmailCodeService::createCode($user, EmailCodeService::TYPE_VERIFY);

        try {
            Mail::to($user->email)->send(new VerificationCodeMail($code));
        } catch (\Throwable $e) {
            Log::error('Failed to send verification email on resend: ' . $e->getMessage());
        }

        return ApiResponse::success(null, $genericMessage);
    }

    public function forgotPassword(ForgotPasswordRequest $request): JsonResponse
    {
        $genericMessage = 'Si un compte existe avec cette adresse email, un code de réinitialisation a été envoyé.';
        $user = User::where('email', $request->email)->first();

        if (! $user) {
            return ApiResponse::success(null, $genericMessage);
        }

        if (EmailCodeService::isThrottled($user, EmailCodeService::TYPE_RESET)) {
            return ApiResponse::error('Veuillez patienter avant de demander un nouveau code.', [
                'email' => ['Veuillez patienter avant de demander un nouveau code.'],
            ], 429);
        }

        $code = EmailCodeService::createCode($user, EmailCodeService::TYPE_RESET);

        try {
            Mail::to($user->email)->send(new ResetPasswordCodeMail($code));
        } catch (\Throwable $e) {
            Log::error('Failed to send reset password email: ' . $e->getMessage());
        }

        return ApiResponse::success(null, $genericMessage);
    }

    public function resetPassword(ResetPasswordRequest $request): JsonResponse
    {
        $user = User::where('email', $request->email)->first();

        if (! $user) {
            return ApiResponse::error('Code invalide ou expiré.', ['code' => ['Le code est invalide ou expiré.']], 422);
        }

        $result = EmailCodeService::verifyCode($user, EmailCodeService::TYPE_RESET, $request->code);

        if (! $result['valid']) {
            return ApiResponse::error($result['message'], ['code' => [$result['message']]], 422);
        }

        $user->password = Hash::make($request->password);
        if ($user->email_verified_at === null) {
            $user->email_verified_at = now();
        }
        $user->save();

        // Revoke all existing tokens
        $user->tokens()->delete();

        return ApiResponse::success(null, 'Mot de passe réinitialisé avec succès.');
    }

    public function changePassword(ChangePasswordRequest $request): JsonResponse
    {
        $user = $request->user();

        if (! Hash::check($request->input('currentPassword'), $user->password)) {
            return ApiResponse::error('Le mot de passe actuel est incorrect.', [
                'currentPassword' => ['Le mot de passe actuel est incorrect.'],
            ], 422);
        }

        $user->password = Hash::make($request->input('password'));
        $user->save();

        return ApiResponse::success(null, 'Mot de passe modifié avec succès.');
    }
}
