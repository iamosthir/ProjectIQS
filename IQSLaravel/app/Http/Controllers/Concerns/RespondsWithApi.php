<?php

namespace App\Http\Controllers\Concerns;

use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Convenience wrappers around {@see ApiResponse} for controllers. Keeps the
 * standard envelope (§0.5) a one-liner in both API and admin controllers.
 */
trait RespondsWithApi
{
    /**
     * @param  array<string, mixed>  $meta
     */
    protected function ok(
        mixed $data = null,
        string $message = 'OK',
        int $status = 200,
        array $meta = [],
    ): JsonResponse {
        return ApiResponse::success($data, $message, $status, $meta);
    }

    /**
     * @param  array<string, mixed>  $meta
     */
    protected function created(mixed $data = null, string $message = 'Created', array $meta = []): JsonResponse
    {
        return ApiResponse::success($data, $message, 201, $meta);
    }

    protected function noContentMessage(string $message = 'OK'): JsonResponse
    {
        return ApiResponse::success(null, $message, 200);
    }

    /**
     * @param  array<string, array<int, string>>|null  $errors
     */
    protected function fail(string $message, ?array $errors = null, int $status = 400): JsonResponse
    {
        return ApiResponse::error($message, $errors, $status);
    }

    /**
     * Resolve a clamped per-page size for list endpoints (default 20, max 50).
     */
    protected function perPage(Request $request, int $default = 20, int $max = 50): int
    {
        return min(max(1, (int) $request->integer('per_page', $default)), $max);
    }
}
