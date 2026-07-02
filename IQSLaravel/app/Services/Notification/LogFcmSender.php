<?php

namespace App\Services\Notification;

use Illuminate\Support\Facades\Log;

/**
 * Local/CI FCM driver — logs instead of sending. Never prunes tokens.
 */
class LogFcmSender implements FcmSender
{
    public function send(array $tokens, string $title, string $body, array $data = [], ?string $image = null): array
    {
        Log::info('FCM push (log driver)', [
            'tokens' => count($tokens),
            'title' => $title,
            'data' => $data,
        ]);

        return [];
    }
}
