<?php

use App\Exceptions\OtpThrottleException;
use App\Http\Middleware\SetLocale;
use App\Support\ApiResponse;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\HttpKernel\Exception\TooManyRequestsHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
        apiPrefix: 'api',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        // Resolve the active locale from the Accept-Language header on every request.
        $middleware->append(SetLocale::class);

        // spatie/laravel-permission middleware aliases (not auto-registered on L11+).
        $middleware->alias([
            'role' => \Spatie\Permission\Middleware\RoleMiddleware::class,
            'permission' => \Spatie\Permission\Middleware\PermissionMiddleware::class,
            'role_or_permission' => \Spatie\Permission\Middleware\RoleOrPermissionMiddleware::class,
        ]);

        // Mobile API stays token-only (no Sanctum stateful/session middleware here).

        // TEMPORARY (test only): skip CSRF on the admin SPA's JSON API. The live
        // server throws "CSRF token mismatch" on every admin request; this unblocks
        // testing. REVERT before production — instead fix SESSION_DOMAIN / APP_URL /
        // SESSION_SECURE_COOKIE (HTTPS) and run `php artisan optimize:clear`.
        $middleware->validateCsrfTokens(except: [
            'admin/api/*',
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // Render the standard JSON envelope (§0.5) for every API / admin-API request.
        $exceptions->render(function (Throwable $e, Request $request) {
            if (! ApiResponse::wantsEnvelope($request)) {
                return null;
            }

            return match (true) {
                $e instanceof ValidationException => ApiResponse::error(
                    $e->getMessage(),
                    $e->errors(),
                    422,
                ),
                $e instanceof AuthenticationException => ApiResponse::error(
                    __('Unauthenticated.'),
                    null,
                    401,
                ),
                $e instanceof AuthorizationException => ApiResponse::error(
                    $e->getMessage() ?: __('This action is unauthorized.'),
                    null,
                    403,
                ),
                $e instanceof ModelNotFoundException,
                $e instanceof NotFoundHttpException => ApiResponse::error(
                    __('Resource not found.'),
                    null,
                    404,
                ),
                $e instanceof OtpThrottleException => ApiResponse::error(
                    $e->getMessage(),
                    null,
                    429,
                    $e->retryAfter,
                ),
                $e instanceof TooManyRequestsHttpException => ApiResponse::error(
                    __('Too many requests.'),
                    null,
                    429,
                    isset($e->getHeaders()['Retry-After']) ? (int) $e->getHeaders()['Retry-After'] : null,
                ),
                $e instanceof HttpExceptionInterface => ApiResponse::error(
                    $e->getMessage() ?: __('Server error.'),
                    null,
                    $e->getStatusCode(),
                ),
                default => ApiResponse::error(
                    config('app.debug') ? $e->getMessage() : __('Server error.'),
                    null,
                    500,
                ),
            };
        });
    })->create();
