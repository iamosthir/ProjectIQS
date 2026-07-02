<?php

namespace App\Support;

use Illuminate\Contracts\Support\Arrayable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Http\Resources\Json\ResourceCollection;
use Illuminate\Pagination\AbstractPaginator;

/**
 * Builds the standard API response envelope used by both the mobile API
 * (`/api/v1/*`) and the admin JSON API (`/admin/api/v1/*`). See §0.5 of the
 * backend plan.
 */
class ApiResponse
{
    /**
     * Should the given request receive the JSON envelope instead of an HTML
     * error page? True for the mobile API, the admin JSON API, and any request
     * that explicitly asks for JSON.
     */
    public static function wantsEnvelope(Request $request): bool
    {
        return $request->is('api/*')
            || $request->is('admin/api/*')
            || $request->expectsJson();
    }

    /**
     * Build a success envelope.
     *
     * @param  array<string, mixed>|Arrayable<string, mixed>|JsonResource|null  $data
     * @param  array<string, mixed>  $meta
     */
    public static function success(
        mixed $data = null,
        string $message = 'OK',
        int $status = 200,
        array $meta = [],
    ): JsonResponse {
        $payload = [
            'success' => true,
            'message' => $message,
        ];

        [$resolvedData, $pagination] = self::resolveData($data);

        $payload['data'] = $resolvedData;

        if ($pagination !== null) {
            $meta = array_merge(['pagination' => $pagination], $meta);
        }

        if ($meta !== []) {
            $payload['meta'] = $meta;
        }

        return response()->json($payload, $status);
    }

    /**
     * Build an error envelope.
     *
     * When $retryAfter is given (e.g. throttling / OTP resend cooldown), it is
     * exposed both as a top-level `retry_after` field (seconds) and the standard
     * `Retry-After` HTTP header so clients can render a countdown.
     *
     * @param  array<string, array<int, string>>|null  $errors
     */
    public static function error(
        string $message,
        ?array $errors = null,
        int $status = 400,
        ?int $retryAfter = null,
    ): JsonResponse {
        $payload = [
            'success' => false,
            'message' => $message,
        ];

        if ($errors !== null) {
            $payload['errors'] = $errors;
        }

        if ($retryAfter !== null) {
            $payload['retry_after'] = $retryAfter;
        }

        $response = response()->json($payload, $status);

        if ($retryAfter !== null) {
            $response->headers->set('Retry-After', (string) $retryAfter);
        }

        return $response;
    }

    /**
     * Normalize the data argument and extract pagination meta when present.
     *
     * @return array{0: mixed, 1: array<string, int>|null}
     */
    protected static function resolveData(mixed $data): array
    {
        $paginator = null;

        if ($data instanceof ResourceCollection || $data instanceof AnonymousResourceCollection) {
            $resource = $data->resource;

            if ($resource instanceof AbstractPaginator) {
                $paginator = $resource;
            }

            return [$data, self::paginationMeta($paginator)];
        }

        if ($data instanceof AbstractPaginator) {
            return [$data->items(), self::paginationMeta($data)];
        }

        return [$data, null];
    }

    /**
     * @return array<string, int>|null
     */
    protected static function paginationMeta(?AbstractPaginator $paginator): ?array
    {
        if ($paginator === null) {
            return null;
        }

        /** @var \Illuminate\Contracts\Pagination\LengthAwarePaginator $paginator */
        return [
            'current_page' => $paginator->currentPage(),
            'per_page' => $paginator->perPage(),
            'total' => $paginator->total(),
            'last_page' => $paginator->lastPage(),
        ];
    }
}
