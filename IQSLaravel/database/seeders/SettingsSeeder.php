<?php

namespace Database\Seeders;

use App\Models\Setting;
use App\Support\Enums\SettingType;
use Illuminate\Database\Seeder;

class SettingsSeeder extends Seeder
{
    /**
     * Seed baseline settings + cross-phase feature flags.
     *
     * @var list<array{group: string, key: string, value: mixed, type: SettingType, is_public: bool}>
     */
    protected array $settings = [
        // General (app-facing)
        ['group' => 'general', 'key' => 'app_name', 'value' => 'IQS', 'type' => SettingType::String, 'is_public' => true],
        ['group' => 'general', 'key' => 'support_email', 'value' => 'support@iqs.app', 'type' => SettingType::String, 'is_public' => true],
        ['group' => 'general', 'key' => 'support_phone', 'value' => '', 'type' => SettingType::String, 'is_public' => true],

        // Match center (Phase 2)
        ['group' => 'match', 'key' => 'auto_top_scorers', 'value' => true, 'type' => SettingType::Boolean, 'is_public' => false],
        ['group' => 'match', 'key' => 'live_poll_seconds', 'value' => 60, 'type' => SettingType::Integer, 'is_public' => true],

        // Marketplace (Phase 3) — contact vs commission monetization mode
        ['group' => 'marketplace', 'key' => 'mode', 'value' => 'contact', 'type' => SettingType::String, 'is_public' => false],

        // Season-gated verification (Phases 4 & 5)
        ['group' => 'clubs', 'key' => 'verification_enabled', 'value' => false, 'type' => SettingType::Boolean, 'is_public' => true],
        ['group' => 'fan_groups', 'key' => 'verification_enabled', 'value' => false, 'type' => SettingType::Boolean, 'is_public' => true],

        // Notifications (Phase 7)
        ['group' => 'notifications', 'key' => 'match_events_enabled', 'value' => true, 'type' => SettingType::Boolean, 'is_public' => false],
    ];

    public function run(): void
    {
        foreach ($this->settings as $setting) {
            Setting::set(
                $setting['group'],
                $setting['key'],
                $setting['value'],
                $setting['type'],
                $setting['is_public'],
            );
        }
    }
}
