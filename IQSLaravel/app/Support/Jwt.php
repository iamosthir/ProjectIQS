<?php

namespace App\Support;

/**
 * Minimal HS256 JWT encode/decode (used by the ZainCash gateway). Avoids an
 * extra dependency for the single algorithm the provider requires.
 */
class Jwt
{
    /**
     * @param  array<string, mixed>  $payload
     */
    public static function encode(array $payload, string $secret): string
    {
        $header = self::base64UrlEncode(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
        $body = self::base64UrlEncode(json_encode($payload));
        $signature = self::sign("{$header}.{$body}", $secret);

        return "{$header}.{$body}.{$signature}";
    }

    /**
     * Decode + verify a token. Returns the payload, or null if invalid.
     *
     * @return array<string, mixed>|null
     */
    public static function decode(string $token, string $secret): ?array
    {
        $parts = explode('.', $token);

        if (count($parts) !== 3) {
            return null;
        }

        [$header, $body, $signature] = $parts;

        if (! hash_equals(self::sign("{$header}.{$body}", $secret), $signature)) {
            return null;
        }

        $payload = json_decode(self::base64UrlDecode($body), true);

        if (! is_array($payload)) {
            return null;
        }

        if (isset($payload['exp']) && $payload['exp'] < time()) {
            return null;
        }

        return $payload;
    }

    protected static function sign(string $data, string $secret): string
    {
        return self::base64UrlEncode(hash_hmac('sha256', $data, $secret, true));
    }

    protected static function base64UrlEncode(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    protected static function base64UrlDecode(string $data): string
    {
        return base64_decode(strtr($data, '-_', '+/')) ?: '';
    }
}
