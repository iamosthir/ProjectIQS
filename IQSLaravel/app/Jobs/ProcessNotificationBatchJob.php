<?php

namespace App\Jobs;

use App\Models\AppNotification;
use App\Models\DeviceToken;
use App\Models\NotificationBatch;
use App\Models\User;
use App\Services\Notification\FcmService;
use App\Support\Enums\NotificationBatchStatus;
use App\Support\Enums\NotificationTarget;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

/**
 * Resolves a broadcast's recipients, fans out per-user notifications, and
 * multicasts the push in chunks, updating delivery counters (§7.2).
 */
class ProcessNotificationBatchJob implements ShouldQueue
{
    use Queueable;

    public function __construct(public readonly int $batchId) {}

    public function handle(FcmService $fcm): void
    {
        $batch = NotificationBatch::find($this->batchId);

        if ($batch === null || $batch->status !== NotificationBatchStatus::Queued) {
            return;
        }

        $batch->update(['status' => NotificationBatchStatus::Sending]);

        $userIds = $this->recipients($batch);
        $batch->update(['total_recipients' => count($userIds)]);

        $payload = [
            'title_ar' => $batch->title_ar, 'title_en' => $batch->title_en,
            'body_ar' => $batch->body_ar, 'body_en' => $batch->body_en,
            'type' => $batch->type->value, 'action_type' => $batch->action_type->value,
            'action_value' => $batch->action_value, 'image_path' => $batch->image_path,
        ];

        $failed = 0;

        foreach (array_chunk($userIds, 500) as $chunk) {
            $now = now();
            AppNotification::insert(array_map(fn (int $uid) => [
                'user_id' => $uid,
                'title_ar' => $batch->title_ar, 'title_en' => $batch->title_en,
                'body_ar' => $batch->body_ar, 'body_en' => $batch->body_en,
                'type' => $batch->type->value, 'action_type' => $batch->action_type->value,
                'action_value' => $batch->action_value, 'image_path' => $batch->image_path,
                'sent_at' => $now, 'created_at' => $now, 'updated_at' => $now,
            ], $chunk));

            $tokens = DeviceToken::query()
                ->whereIn('user_id', $chunk)
                ->where('is_active', true)
                ->pluck('token')
                ->all();

            $failed += $fcm->pushTokens($tokens, $payload);
        }

        $batch->update([
            'status' => NotificationBatchStatus::Sent,
            'sent_count' => count($userIds),
            'failed_count' => $failed,
            'sent_at' => now(),
        ]);
    }

    /**
     * @return list<int>
     */
    protected function recipients(NotificationBatch $batch): array
    {
        $value = $batch->target_value ?? [];

        return match ($batch->target) {
            NotificationTarget::All => User::query()
                ->where('is_active', true)->where('is_banned', false)->pluck('id')->all(),
            NotificationTarget::ClubSupporters => User::query()
                ->where('supported_club_id', $value['club_id'] ?? 0)->pluck('id')->all(),
            NotificationTarget::Governorate => User::query()
                ->where('governorate', $value['governorate'] ?? '')->pluck('id')->all(),
            NotificationTarget::Custom => array_values(array_map('intval', $value['user_ids'] ?? [])),
        };
    }
}
