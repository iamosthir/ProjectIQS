<?php

namespace App\Services\Notification;

use App\Models\AppNotification;
use App\Models\DeviceToken;
use App\Models\Fixture;
use App\Models\Setting;
use App\Models\User;
use App\Support\Enums\NotificationType;

/**
 * Pushes live match events (kickoff / goal / full-time) to users following
 * either team or its club (§7.2). Gated by settings.notifications.match_events_enabled.
 */
class MatchNotificationService
{
    public function __construct(private readonly FcmService $fcm) {}

    public function notifyKickoff(Fixture $fixture): void
    {
        $this->notify($fixture, NotificationType::Match, 'بدأت المباراة', 'Match started',
            $this->teamsAr($fixture).' بدأت الآن', $this->teamsEn($fixture).' has kicked off');
    }

    public function notifyGoal(Fixture $fixture): void
    {
        $score = ($fixture->home_goals ?? 0).' - '.($fixture->away_goals ?? 0);
        $this->notify($fixture, NotificationType::Goal, '⚽ هدف!', '⚽ Goal!',
            $this->teamsAr($fixture).'  '.$score, $this->teamsEn($fixture).'  '.$score);
    }

    public function notifyFullTime(Fixture $fixture): void
    {
        $score = ($fixture->home_goals ?? 0).' - '.($fixture->away_goals ?? 0);
        $this->notify($fixture, NotificationType::Match, 'انتهت المباراة', 'Full time',
            $this->teamsAr($fixture).'  '.$score, $this->teamsEn($fixture).'  '.$score);
    }

    protected function notify(Fixture $fixture, NotificationType $type, string $titleAr, string $titleEn, string $bodyAr, string $bodyEn): void
    {
        if (! (bool) Setting::get('notifications', 'match_events_enabled', true)) {
            return;
        }

        $userIds = $this->followers($fixture);

        if ($userIds === []) {
            return;
        }

        $payload = [
            'title_ar' => $titleAr, 'title_en' => $titleEn, 'body_ar' => $bodyAr, 'body_en' => $bodyEn,
            'type' => $type->value, 'action_type' => 'fixture', 'action_value' => (string) $fixture->id,
        ];

        $now = now();
        AppNotification::insert(array_map(fn (int $uid) => array_merge($payload, [
            'user_id' => $uid, 'sent_at' => $now, 'created_at' => $now, 'updated_at' => $now,
        ]), $userIds));

        $tokens = DeviceToken::query()
            ->whereIn('user_id', $userIds)
            ->where('is_active', true)
            ->pluck('token')
            ->all();

        $this->fcm->pushTokens($tokens, $payload);
    }

    /**
     * @return list<int>
     */
    protected function followers(Fixture $fixture): array
    {
        $fixture->loadMissing('homeTeam', 'awayTeam');
        $teamIds = array_filter([$fixture->home_team_id, $fixture->away_team_id]);
        $clubIds = array_filter([$fixture->homeTeam?->club_id, $fixture->awayTeam?->club_id]);

        return User::query()
            ->where(function ($q) use ($teamIds, $clubIds): void {
                $q->whereIn('supported_team_id', $teamIds);
                if ($clubIds !== []) {
                    $q->orWhereIn('supported_club_id', $clubIds);
                }
            })
            ->where('is_active', true)
            ->where('is_banned', false)
            ->pluck('id')
            ->all();
    }

    protected function teamsAr(Fixture $fixture): string
    {
        $fixture->loadMissing('homeTeam', 'awayTeam');

        return ($fixture->homeTeam?->name_ar ?? '').' × '.($fixture->awayTeam?->name_ar ?? '');
    }

    protected function teamsEn(Fixture $fixture): string
    {
        $fixture->loadMissing('homeTeam', 'awayTeam');

        return ($fixture->homeTeam?->name_en ?? '').' vs '.($fixture->awayTeam?->name_en ?? '');
    }
}
