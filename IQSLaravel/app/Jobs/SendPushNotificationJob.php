<?php

namespace App\Jobs;

use App\Models\User;
use App\Services\Notification\FcmService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class SendPushNotificationJob implements ShouldQueue
{
    use Queueable;

    /**
     * @param  array<string, mixed>  $payload
     */
    public function __construct(
        public readonly int $userId,
        public readonly array $payload,
    ) {}

    public function handle(FcmService $fcm): void
    {
        $user = User::find($this->userId);

        if ($user !== null) {
            $fcm->notifyUser($user, $this->payload);
        }
    }
}
