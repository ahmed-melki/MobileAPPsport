<?php

namespace Tests\Feature;

use App\Mail\ResetPasswordCodeMail;
use App\Mail\VerificationCodeMail;
use App\Models\EmailCode;
use App\Models\User;
use App\Support\EmailCodeService;
use App\Support\TrainingCatalog;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class AuthCodeFlowTest extends TestCase
{
    use RefreshDatabase;

    public function test_registration_sends_verification_email_with_code_and_returns_email_verified_false(): void
    {
        Mail::fake();

        $payload = [
            'firstName' => 'Lucas',
            'lastName' => 'Bernard',
            'email' => 'lucas.bernard@example.com',
            'password' => 'Password123!',
            'passwordConfirmation' => 'Password123!',
        ];

        $response = $this->postJson('/api/auth/register', $payload)
            ->assertStatus(201)
            ->assertJsonPath('data.user.email', 'lucas.bernard@example.com')
            ->assertJsonPath('data.user.emailVerified', false)
            ->assertJsonPath('data.emailSent', true)
            ->assertJsonPath('data.token', fn ($token) => ! empty($token));

        Mail::assertSent(VerificationCodeMail::class, function ($mail) {
            return $mail->hasTo('lucas.bernard@example.com') && strlen($mail->code) === 6;
        });

        $user = User::where('email', 'lucas.bernard@example.com')->firstOrFail();
        $this->assertNull($user->email_verified_at);

        $codeRecord = EmailCode::where('user_id', $user->id)->where('type', 'verify')->first();
        $this->assertNotNull($codeRecord);
        $this->assertSame(0, $codeRecord->attempts);
        $this->assertNull($codeRecord->used_at);
        $this->assertTrue($codeRecord->expires_at->isFuture());
    }

    public function test_registration_succeeds_even_if_mail_sending_fails(): void
    {
        Mail::shouldReceive('to->send')
            ->andThrow(new \RuntimeException('SMTP Connection Error'));

        $payload = [
            'firstName' => 'Camille',
            'lastName' => 'Roux',
            'email' => 'camille.roux@example.com',
            'password' => 'Password123!',
            'passwordConfirmation' => 'Password123!',
        ];

        $this->postJson('/api/auth/register', $payload)
            ->assertStatus(201)
            ->assertJsonPath('data.user.email', 'camille.roux@example.com')
            ->assertJsonPath('data.user.emailVerified', false)
            ->assertJsonPath('data.emailSent', false);

        $this->assertDatabaseHas('users', ['email' => 'camille.roux@example.com']);
    }

    public function test_unverified_user_login_works_and_returns_email_verified_false(): void
    {
        $user = User::factory()->unverified()->create([
            'email' => 'unverified@example.com',
            'password' => Hash::make('Password123!'),
        ]);

        $this->postJson('/api/auth/login', [
            'email' => 'unverified@example.com',
            'password' => 'Password123!',
        ])->assertOk()
            ->assertJsonPath('data.user.emailVerified', false)
            ->assertJsonPath('data.token', fn ($token) => ! empty($token));
    }

    public function test_unverified_user_gets_403_on_protected_routes_except_exempt(): void
    {
        TrainingCatalog::ensureSeeded();

        $user = User::factory()->unverified()->create();
        $this->actingAs($user, 'sanctum');

        // Exempt routes work
        $this->getJson('/api/me')
            ->assertOk()
            ->assertJsonPath('data.emailVerified', false);

        $this->postJson('/api/auth/logout')
            ->assertOk();

        // Re-authenticate
        $this->actingAs($user, 'sanctum');

        // Protected routes return 403 with code email_not_verified
        $this->getJson('/api/exercises')
            ->assertStatus(403)
            ->assertJsonPath('code', 'email_not_verified');

        $this->putJson('/api/me', ['bio' => 'Updated bio'])
            ->assertStatus(403)
            ->assertJsonPath('code', 'email_not_verified');

        $this->getJson('/api/me/recommendations')
            ->assertStatus(403)
            ->assertJsonPath('code', 'email_not_verified');
    }

    public function test_verify_email_with_correct_code_verifies_user_and_unlocks_routes(): void
    {
        $user = User::factory()->unverified()->create();
        $code = EmailCodeService::createCode($user, EmailCodeService::TYPE_VERIFY);

        $this->postJson('/api/auth/verify-email', [
            'email' => $user->email,
            'code' => $code,
        ])->assertOk()
            ->assertJsonPath('data.user.emailVerified', true);

        $this->assertNotNull($user->fresh()->email_verified_at);

        // Protected route now accessible
        $this->actingAs($user->fresh(), 'sanctum');
        $this->getJson('/api/exercises')->assertOk();
    }

    public function test_verify_email_with_wrong_code_increments_attempts_and_returns_422(): void
    {
        $user = User::factory()->unverified()->create();
        EmailCodeService::createCode($user, EmailCodeService::TYPE_VERIFY);

        $this->postJson('/api/auth/verify-email', [
            'email' => $user->email,
            'code' => '000000',
        ])->assertStatus(422)
            ->assertJsonValidationErrors(['code']);

        $codeRecord = EmailCode::where('user_id', $user->id)->where('type', 'verify')->first();
        $this->assertSame(1, $codeRecord->attempts);
        $this->assertNull($user->fresh()->email_verified_at);
    }

    public function test_verify_email_with_expired_code_returns_422(): void
    {
        $user = User::factory()->unverified()->create();
        $code = EmailCodeService::createCode($user, EmailCodeService::TYPE_VERIFY);

        // Expire the code
        EmailCode::where('user_id', $user->id)->update([
            'expires_at' => now()->subMinute(),
        ]);

        $this->postJson('/api/auth/verify-email', [
            'email' => $user->email,
            'code' => $code,
        ])->assertStatus(422)
            ->assertJsonValidationErrors(['code']);
    }

    public function test_code_locks_out_after_max_5_attempts(): void
    {
        $user = User::factory()->unverified()->create();
        $code = EmailCodeService::createCode($user, EmailCodeService::TYPE_VERIFY);

        // 5 wrong attempts
        for ($i = 1; $i <= 5; $i++) {
            $this->postJson('/api/auth/verify-email', [
                'email' => $user->email,
                'code' => '999999',
            ])->assertStatus(422);
        }

        $codeRecord = EmailCode::where('user_id', $user->id)->where('type', 'verify')->first();
        $this->assertSame(5, $codeRecord->attempts);

        // Even with the correct code, it is locked
        $this->postJson('/api/auth/verify-email', [
            'email' => $user->email,
            'code' => $code,
        ])->assertStatus(422)
            ->assertJsonValidationErrors(['code']);
    }

    public function test_creating_new_code_invalidates_older_unused_codes_so_only_newest_works(): void
    {
        Mail::fake();

        $user = User::factory()->unverified()->create();
        $firstCode = EmailCodeService::createCode($user, EmailCodeService::TYPE_VERIFY);

        // Fast-forward past 1-minute cooldown
        Carbon::setTestNow(now()->addSeconds(65));

        $this->postJson('/api/auth/resend-code', [
            'email' => $user->email,
        ])->assertOk();

        // The older code must not work
        $this->postJson('/api/auth/verify-email', [
            'email' => $user->email,
            'code' => $firstCode,
        ])->assertStatus(422);

        // Find newest code
        $latestRecord = EmailCode::where('user_id', $user->id)->whereNull('used_at')->first();
        $this->assertNotNull($latestRecord);

        // Retrieve latest code from sent mail
        $sentMails = Mail::sent(VerificationCodeMail::class);
        $newestCode = $sentMails->last()->code;

        $this->postJson('/api/auth/verify-email', [
            'email' => $user->email,
            'code' => $newestCode,
        ])->assertOk()
            ->assertJsonPath('data.user.emailVerified', true);

        Carbon::setTestNow();
    }

    public function test_resend_code_is_throttled_to_once_per_minute(): void
    {
        Mail::fake();

        $user = User::factory()->unverified()->create();
        EmailCodeService::createCode($user, EmailCodeService::TYPE_VERIFY);

        // Immediate resend should be throttled
        $this->postJson('/api/auth/resend-code', [
            'email' => $user->email,
        ])->assertStatus(429);

        // After 65 seconds, resend succeeds
        Carbon::setTestNow(now()->addSeconds(65));

        $this->postJson('/api/auth/resend-code', [
            'email' => $user->email,
        ])->assertOk();

        Carbon::setTestNow();
    }

    public function test_resend_code_and_forgot_password_return_generic_response_for_unknown_and_verified_emails(): void
    {
        Mail::fake();

        // Unknown email resend
        $this->postJson('/api/auth/resend-code', [
            'email' => 'ghost@apex.app',
        ])->assertOk();

        // Already verified email resend
        $verifiedUser = User::factory()->create();
        $this->postJson('/api/auth/resend-code', [
            'email' => $verifiedUser->email,
        ])->assertOk();

        // Unknown email forgot password
        $this->postJson('/api/auth/forgot-password', [
            'email' => 'ghost@apex.app',
        ])->assertOk();

        Mail::assertNothingSent();
    }

    public function test_reset_password_updates_password_revokes_tokens_and_verifies_email(): void
    {
        Mail::fake();

        $user = User::factory()->unverified()->create([
            'password' => Hash::make('OldPassword123!'),
        ]);

        $token1 = $user->createToken('token1')->plainTextToken;
        $token2 = $user->createToken('token2')->plainTextToken;
        $this->assertCount(2, $user->tokens);

        $resetCode = EmailCodeService::createCode($user, EmailCodeService::TYPE_RESET);

        $this->postJson('/api/auth/reset-password', [
            'email' => $user->email,
            'code' => $resetCode,
            'password' => 'NewSecurePassword123!',
            'passwordConfirmation' => 'NewSecurePassword123!',
        ])->assertOk();

        // Tokens revoked
        $this->assertCount(0, $user->fresh()->tokens);

        // Password updated
        $this->assertTrue(Hash::check('NewSecurePassword123!', $user->fresh()->password));

        // Email verified if was empty
        $this->assertNotNull($user->fresh()->email_verified_at);

        // Can login with new password
        $this->postJson('/api/auth/login', [
            'email' => $user->email,
            'password' => 'NewSecurePassword123!',
        ])->assertOk()
            ->assertJsonPath('data.user.emailVerified', true);
    }

    public function test_change_password_validates_current_password_and_updates(): void
    {
        $user = User::factory()->create([
            'password' => Hash::make('CurrentPassword123!'),
        ]);
        $this->actingAs($user, 'sanctum');

        // Wrong current password
        $this->postJson('/api/me/change-password', [
            'currentPassword' => 'WrongPassword!',
            'password' => 'BrandNewPassword123!',
            'passwordConfirmation' => 'BrandNewPassword123!',
        ])->assertStatus(422)
            ->assertJsonValidationErrors(['currentPassword']);

        // Correct change
        $this->postJson('/api/me/change-password', [
            'currentPassword' => 'CurrentPassword123!',
            'password' => 'BrandNewPassword123!',
            'passwordConfirmation' => 'BrandNewPassword123!',
        ])->assertOk();

        $this->assertTrue(Hash::check('BrandNewPassword123!', $user->fresh()->password));
    }
}
