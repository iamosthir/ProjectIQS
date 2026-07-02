<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Auth\RegisterRequest;
use App\Http\Requests\Api\Auth\RequestOtpRequest;
use App\Http\Requests\Api\Auth\UpdateProfileRequest;
use App\Http\Requests\Api\Auth\VerifyOtpRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Services\Auth\OtpService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function __construct(private readonly OtpService $otp) {}

    /**
     * Generate and send an OTP for the given phone.
     */
    public function requestOtp(RequestOtpRequest $request): JsonResponse
    {
        $phone = $request->phoneE164();

        $result = $this->otp->request($phone, $request->otpPurpose(), $request->ip());

        $data = [
            'phone' => $this->maskPhone($phone),
            'expires_at' => $result['otp']->expires_at->toIso8601String(),
            'expires_in' => (int) config('otp.ttl_minutes') * 60,
            // Seconds the client must wait before another code can be requested
            // (drives the resend countdown). A too-early resend returns 429 with
            // a `retry_after` that supersedes this.
            'resend_available_in' => (int) config('otp.resend_cooldown_seconds'),
        ];

        // Local/CI only — never enabled in production (config/otp.php).
        if (config('otp.expose_code')) {
            $data['debug_otp'] = $result['code'];
        }

        return $this->ok($data, __('A verification code has been sent.'));
    }

    /**
     * Verify the OTP, create the user if new, and issue a Sanctum token.
     */
    public function verifyOtp(VerifyOtpRequest $request): JsonResponse
    {
        $phone = $request->phoneE164();

        $this->otp->verify($phone, (string) $request->input('otp'), $request->otpPurpose());

        $user = User::where('phone', $phone)->first();
        $isNew = false;

        if ($user === null) {
            $user = User::create([
                'phone' => $phone,
                'phone_verified_at' => now(),
                'last_active_at' => now(),
                'locale' => app()->getLocale(),
            ]);
            $isNew = true;
        } else {
            $user->forceFill([
                'phone_verified_at' => $user->phone_verified_at ?? now(),
                'last_active_at' => now(),
            ])->save();
        }

        if ($user->is_banned) {
            return $this->fail(__('This account has been suspended.'), null, 403);
        }

        $token = $user->createToken('mobile')->plainTextToken;

        return $this->ok([
            'token' => $token,
            'token_type' => 'Bearer',
            'user' => new UserResource($user),
            'is_new' => $isNew,
            'needs_registration' => ! $user->hasCompletedRegistration(),
        ], __('Signed in successfully.'));
    }

    /**
     * Complete the profile form after first login.
     */
    public function register(RegisterRequest $request): JsonResponse
    {
        $user = $request->user();

        $user->fill($request->validated());
        $user->registration_completed_at ??= now();
        $user->save();

        return $this->ok(new UserResource($user->fresh()), __('Profile completed.'));
    }

    /**
     * The current authenticated user.
     */
    public function me(Request $request): JsonResponse
    {
        return $this->ok(new UserResource($request->user()));
    }

    /**
     * Update editable profile fields.
     */
    public function updateProfile(UpdateProfileRequest $request): JsonResponse
    {
        $user = $request->user();
        $user->fill($request->validated());
        $user->save();

        return $this->ok(new UserResource($user->fresh()), __('Profile updated.'));
    }

    /**
     * Revoke the current access token.
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return $this->noContentMessage(__('Signed out.'));
    }

    /**
     * Permanently delete the account (App Store / Play requirement).
     * Soft-deletes the user, revokes every token, and anonymizes PII so the
     * original phone/email can be reused.
     */
    public function deleteAccount(Request $request): JsonResponse
    {
        $user = $request->user();

        $user->tokens()->delete();
        $user->deviceTokens()->delete();

        $user->forceFill([
            'phone' => 'deleted_'.$user->id.'_'.Str::random(8),
            'name' => null,
            'email' => null,
            'avatar' => null,
            'is_active' => false,
        ])->save();

        $user->delete();

        return $this->noContentMessage(__('Your account has been deleted.'));
    }

    /**
     * Mask the middle digits of an E.164 phone for display.
     */
    protected function maskPhone(string $phone): string
    {
        $length = strlen($phone);

        if ($length <= 7) {
            return $phone;
        }

        return substr($phone, 0, 4).str_repeat('*', $length - 7).substr($phone, -3);
    }
}
