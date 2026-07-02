<?php

namespace Tests\Feature\Api;

use App\Models\OtpVerification;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AuthOtpTest extends TestCase
{
    use RefreshDatabase;

    private const PHONE = '+9647712345678';

    public function test_request_otp_returns_envelope_and_debug_code(): void
    {
        $response = $this->postJson('/api/v1/auth/request-otp', ['phone' => self::PHONE]);

        $response->assertOk()
            ->assertJson(['success' => true])
            ->assertJsonStructure(['success', 'message', 'data' => ['phone', 'expires_at', 'expires_in', 'resend_available_in', 'debug_otp']]);

        $this->assertDatabaseHas('otp_verifications', ['phone' => self::PHONE, 'purpose' => 'login']);
    }

    public function test_full_otp_cycle_creates_user_and_issues_token(): void
    {
        $code = $this->postJson('/api/v1/auth/request-otp', ['phone' => self::PHONE])
            ->json('data.debug_otp');

        $verify = $this->postJson('/api/v1/auth/verify-otp', [
            'phone' => self::PHONE,
            'otp' => $code,
        ]);

        $verify->assertOk()
            ->assertJson(['success' => true, 'data' => ['is_new' => true, 'needs_registration' => true]])
            ->assertJsonStructure(['data' => ['token', 'user' => ['id', 'phone']]]);

        $this->assertDatabaseHas('users', ['phone' => self::PHONE]);

        $token = $verify->json('data.token');

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/v1/auth/me')
            ->assertOk()
            ->assertJsonPath('data.phone', self::PHONE);
    }

    public function test_otp_is_hashed_at_rest(): void
    {
        $code = $this->postJson('/api/v1/auth/request-otp', ['phone' => self::PHONE])
            ->json('data.debug_otp');

        $otp = OtpVerification::where('phone', self::PHONE)->first();

        $this->assertNotSame($code, $otp->otp_code);
    }

    public function test_verify_with_wrong_code_fails(): void
    {
        $code = $this->postJson('/api/v1/auth/request-otp', ['phone' => self::PHONE])
            ->json('data.debug_otp');

        $wrong = $code[0] === '0' ? '1'.substr($code, 1) : '0'.substr($code, 1);

        $this->postJson('/api/v1/auth/verify-otp', ['phone' => self::PHONE, 'otp' => $wrong])
            ->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonValidationErrors('otp');
    }

    public function test_otp_locks_after_max_attempts(): void
    {
        $code = $this->postJson('/api/v1/auth/request-otp', ['phone' => self::PHONE])
            ->json('data.debug_otp');

        $wrong = $code[0] === '0' ? '1'.substr($code, 1) : '0'.substr($code, 1);

        for ($i = 0; $i < (int) config('otp.max_attempts'); $i++) {
            $this->postJson('/api/v1/auth/verify-otp', ['phone' => self::PHONE, 'otp' => $wrong])
                ->assertStatus(422);
        }

        // Even the correct code is now rejected — the OTP is locked.
        $this->postJson('/api/v1/auth/verify-otp', ['phone' => self::PHONE, 'otp' => $code])
            ->assertStatus(422)
            ->assertJsonValidationErrors('otp');
    }

    public function test_register_completes_profile(): void
    {
        $user = User::factory()->unregistered()->create(['phone' => self::PHONE]);
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/auth/register', ['name' => 'Ali Hassan', 'governorate' => 'Baghdad'])
            ->assertOk()
            ->assertJsonPath('data.name', 'Ali Hassan')
            ->assertJsonPath('data.is_registration_completed', true);

        $this->assertNotNull($user->fresh()->registration_completed_at);
    }

    public function test_logout_revokes_current_token(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('mobile')->plainTextToken;

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/auth/logout')
            ->assertOk();

        $this->assertSame(0, $user->tokens()->count());
    }

    public function test_delete_account_soft_deletes_and_revokes_tokens(): void
    {
        $user = User::factory()->create(['phone' => self::PHONE]);
        $token = $user->createToken('mobile')->plainTextToken;

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->deleteJson('/api/v1/auth/account')
            ->assertOk();

        $this->assertSoftDeleted('users', ['id' => $user->id]);
        $this->assertSame(0, $user->tokens()->count());
        // Phone is anonymized so it can be reused.
        $this->assertDatabaseMissing('users', ['phone' => self::PHONE, 'deleted_at' => null]);
    }

    public function test_invalid_phone_is_rejected(): void
    {
        $this->postJson('/api/v1/auth/request-otp', ['phone' => 'not-a-phone'])
            ->assertStatus(422)
            ->assertJsonValidationErrors('phone');
    }

    public function test_resend_cooldown_returns_429_with_retry_after(): void
    {
        // The test env disables the cooldown (OTP_RESEND_COOLDOWN=0); enable it here.
        config(['otp.resend_cooldown_seconds' => 60]);

        $this->postJson('/api/v1/auth/request-otp', ['phone' => self::PHONE])->assertOk();

        $response = $this->postJson('/api/v1/auth/request-otp', ['phone' => self::PHONE]);

        $response->assertStatus(429)
            ->assertJsonPath('success', false)
            ->assertJsonStructure(['success', 'message', 'retry_after'])
            ->assertHeader('Retry-After');

        $retryAfter = $response->json('retry_after');
        $this->assertIsInt($retryAfter);
        $this->assertGreaterThan(0, $retryAfter);
        $this->assertLessThanOrEqual(60, $retryAfter);
    }
}
