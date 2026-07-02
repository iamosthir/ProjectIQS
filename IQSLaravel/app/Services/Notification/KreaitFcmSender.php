<?php

namespace App\Services\Notification;

use Kreait\Firebase\Contract\Messaging;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;
use Throwable;

/**
 * Production FCM driver via kreait/laravel-firebase. Resolves Messaging lazily
 * so the app boots even without credentials when another driver is active.
 */
class KreaitFcmSender implements FcmSender
{
    public function send(array $tokens, string $title, string $body, array $data = [], ?string $image = null): array
    {
        if ($tokens === []) {
            return [];
        }

        /** @var Messaging $messaging */
        $messaging = app(Messaging::class);

        $message = CloudMessage::new()
            ->withNotification(Notification::create($title, $body, $image))
            ->withData($data);

        try {
            $report = $messaging->sendMulticast($message, $tokens);
        } catch (Throwable) {
            return [];
        }

        return array_values(array_unique(array_merge(
            $report->invalidTokens(),
            $report->unknownTokens(),
        )));
    }
}
