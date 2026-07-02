<?php

namespace Tests\Feature\Notification;

use App\Models\AppNotification;
use App\Models\DeviceToken;
use App\Models\Fixture;
use App\Models\Setting;
use App\Models\Team;
use App\Models\User;
use App\Services\Notification\FcmSender;
use App\Services\Notification\MatchNotificationService;
use App\Support\Enums\SettingType;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Support\FakeFcmSender;
use Tests\TestCase;

class MatchNotificationTest extends TestCase
{
    use RefreshDatabase;

    private FakeFcmSender $fcm;

    protected function setUp(): void
    {
        parent::setUp();
        $this->fcm = new FakeFcmSender;
        $this->app->instance(FcmSender::class, $this->fcm);
    }

    public function test_full_time_notifies_team_followers_only(): void
    {
        $home = Team::factory()->create();
        $away = Team::factory()->create();
        $fixture = Fixture::factory()->finished(2, 1)->create(['home_team_id' => $home->id, 'away_team_id' => $away->id]);

        $follower = User::factory()->create(['supported_team_id' => $home->id]);
        DeviceToken::factory()->for($follower)->create(['token' => 'follower-token']);
        $stranger = User::factory()->create(); // follows nothing

        app(MatchNotificationService::class)->notifyFullTime($fixture);

        $this->assertDatabaseHas('app_notifications', [
            'user_id' => $follower->id, 'type' => 'match', 'action_type' => 'fixture', 'action_value' => (string) $fixture->id,
        ]);
        $this->assertDatabaseMissing('app_notifications', ['user_id' => $stranger->id]);
        $this->assertContains('follower-token', $this->fcm->sentTokens);
    }

    public function test_match_events_can_be_disabled_by_setting(): void
    {
        Setting::set('notifications', 'match_events_enabled', false, SettingType::Boolean);

        $fixture = Fixture::factory()->finished()->create();
        User::factory()->create(['supported_team_id' => $fixture->home_team_id]);

        app(MatchNotificationService::class)->notifyFullTime($fixture);

        $this->assertSame(0, AppNotification::count());
        $this->assertSame(0, $this->fcm->calls);
    }
}
