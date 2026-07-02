<?php

namespace App\Services\Notification;

/**
 * Abstraction over the FCM transport. The concrete driver is chosen in
 * config/services.php (`fcm.driver`); a `log` driver is used until Firebase
 * credentials are wired.
 */
interface FcmSender
{
    /**
     * Push to the given tokens and return the list of invalid / unregistered
     * tokens that should be pruned.
     *
     * @param  list<string>  $tokens
     * @param  array<string, string>  $data
     * @return list<string>
     */
    public function send(array $tokens, string $title, string $body, array $data = [], ?string $image = null): array;
}
