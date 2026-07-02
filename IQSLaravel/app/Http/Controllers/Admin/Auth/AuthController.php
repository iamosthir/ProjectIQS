<?php

namespace App\Http\Controllers\Admin\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\Auth\LoginRequest;
use App\Http\Resources\Admin\AdminResource;
use App\Models\Admin;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;

/**
 * Admin panel session auth (web guard). Same-origin SPA → CSRF via the
 * standard web middleware (§0.4 / §9.2).
 */
class AuthController extends Controller
{
    /**
     * Establish an admin session.
     */
    public function login(LoginRequest $request): JsonResponse
    {
        $credentials = $request->only('email', 'password');

        if (! Auth::guard('web')->attempt($credentials, $request->boolean('remember'))) {
            throw ValidationException::withMessages([
                'email' => [__('auth.failed')],
            ]);
        }

        /** @var Admin $admin */
        $admin = Auth::guard('web')->user();

        if (! $admin->is_active) {
            Auth::guard('web')->logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();

            return $this->fail(__('This account is inactive.'), null, 403);
        }

        $request->session()->regenerate();
        $admin->forceFill(['last_login_at' => now()])->save();

        return $this->ok($this->sessionPayload($admin), __('Signed in successfully.'));
    }

    /**
     * The current admin + roles/permissions (consumed by the SPA auth store).
     */
    public function me(Request $request): JsonResponse
    {
        /** @var Admin $admin */
        $admin = $request->user();

        return $this->ok($this->sessionPayload($admin));
    }

    /**
     * Tear down the admin session.
     */
    public function logout(Request $request): JsonResponse
    {
        Auth::guard('web')->logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return $this->noContentMessage(__('Signed out.'));
    }

    /**
     * @return array<string, mixed>
     */
    protected function sessionPayload(Admin $admin): array
    {
        return [
            'admin' => new AdminResource($admin),
            'roles' => $admin->getRoleNames(),
            'permissions' => $admin->getAllPermissions()->pluck('name')->values(),
        ];
    }
}
