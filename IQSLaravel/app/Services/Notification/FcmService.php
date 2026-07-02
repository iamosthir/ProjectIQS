<?php

namespace App\Services\Notification;

use App\Models\AppNotification;
use App\Models\DeviceToken;
use App\Models\User;
use Illuminate\Support\Arr;

/**
 * Persists app notifications and pushes them to a user's devices, pruning
 * invalid FCM tokens on failure (§7.2).
 */
class FcmService
{
    public function __construct(private readonly FcmSender $sender) {}

    /**
     * Persist a notification for a user and push it to their devices.
     *
     * @param  array<string, mixed>  $payload
     */
    public function notifyUser(User $user, array $payload): AppNotification
    {
        $notification = AppNotification::create(array_merge($this->persistable($payload), [
            'user_id' => $user->id,
            'sent_at' => now(),
        ]));

        $this->pushToUser($user, $payload);

        return $notification;
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function pushToUser(User $user, array $payload): void
    {
        $tokens = $user->deviceTokens()->where('is_active', true)->pluck('token')->all();

        $this->pushTokens($tokens, $payload, $user->locale ?? 'ar');
    }

    /**
     * @param  list<string>  $tokens
     * @param  array<string, mixed>  $payload
     */
    public function pushTokens(array $tokens, array $payload, string $locale = 'ar'): int
    {
        if ($tokens === []) {
            return 0;
        }

        $title = $locale === 'en'
            ? ($payload['title_en'] ?? $payload['title_ar'] ?? '')
            : ($payload['title_ar'] ?? $payload['title_en'] ?? '');
        $body = $locale === 'en'
            ? ($payload['body_en'] ?? $payload['body_ar'] ?? '')
            : ($payload['body_ar'] ?? $payload['body_en'] ?? '');

        $data = array_filter([
            'type' => (string) ($payload['type'] ?? 'general'),
            'action_type' => (string) ($payload['action_type'] ?? 'none'),
            'action_value' => $payload['action_value'] ?? null,
        ], fn ($v) => $v !== null);

        $invalid = $this->sender->send($tokens, (string) $title, (string) $body, $data, $payload['image_path'] ?? null);
        $this->prune($invalid);

        return count($invalid);
    }

    /**
     * @param  list<string>  $invalid
     */
    protected function prune(array $invalid): void
    {
        if ($invalid !== []) {
            DeviceToken::whereIn('token', $invalid)->update(['is_active' => false]);
        }
    }

    /**
     * @param  array<string, mixed>  $payload
     * @return array<string, mixed>
     */
    protected function persistable(array $payload): array
    {
        return Arr::only($payload, [
            'title_ar', 'title_en', 'body_ar', 'body_en', 'type',
            'action_type', 'action_value', 'image_path', 'data',
        ]);
    }
}
