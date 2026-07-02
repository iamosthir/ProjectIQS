<?php

namespace Tests\Feature\Api;

use App\Models\AppVersion;
use App\Models\Page;
use App\Models\Setting;
use App\Support\Enums\SettingType;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AppConfigTest extends TestCase
{
    use RefreshDatabase;

    public function test_app_config_is_public_and_returns_public_settings(): void
    {
        Setting::set('general', 'support_email', 'help@iqs.iq', SettingType::String, true);
        Setting::set('general', 'secret_key', 'hidden', SettingType::String, false);

        $settings = $this->getJson('/api/v1/app/config')
            ->assertOk()
            ->json('data.settings');

        $this->assertSame('help@iqs.iq', $settings['general.support_email']);
        $this->assertArrayNotHasKey('general.secret_key', $settings);
    }

    public function test_version_gate_flags_force_update_below_min_supported(): void
    {
        AppVersion::create([
            'platform' => 'android',
            'version' => '2.0.0',
            'build_number' => 20,
            'min_supported_version' => '1.5.0',
            'is_force_update' => false,
            'store_url' => 'https://play.google.com/store/apps/details?id=iq.iqs',
            'is_active' => true,
        ]);

        $this->getJson('/api/v1/app/config?platform=android&version=1.0.0')
            ->assertOk()
            ->assertJsonPath('data.version.latest', '2.0.0')
            ->assertJsonPath('data.version.update_available', true)
            ->assertJsonPath('data.version.force_update', true);

        $this->getJson('/api/v1/app/config?platform=android&version=1.9.0')
            ->assertOk()
            ->assertJsonPath('data.version.update_available', true)
            ->assertJsonPath('data.version.force_update', false);

        $this->getJson('/api/v1/app/config?platform=android&version=2.0.0')
            ->assertOk()
            ->assertJsonPath('data.version.update_available', false)
            ->assertJsonPath('data.version.force_update', false);
    }

    public function test_governorates_are_public_and_localized(): void
    {
        $this->getJson('/api/v1/governorates', ['Accept-Language' => 'ar'])
            ->assertOk()
            ->assertJsonCount(18, 'data')
            ->assertJsonPath('data.0.code', 'baghdad')
            ->assertJsonPath('data.0.name', 'بغداد');

        $this->getJson('/api/v1/governorates', ['Accept-Language' => 'en'])
            ->assertOk()
            ->assertJsonPath('data.0.name', 'Baghdad');
    }

    public function test_static_page_is_reachable_without_auth(): void
    {
        Page::factory()->create(['slug' => 'privacy', 'title_en' => 'Privacy Policy', 'is_active' => true]);

        $this->getJson('/api/v1/pages/privacy')
            ->assertOk()
            ->assertJsonPath('data.slug', 'privacy');
    }

    public function test_inactive_page_returns_404(): void
    {
        Page::factory()->create(['slug' => 'draft', 'is_active' => false]);

        $this->getJson('/api/v1/pages/draft')->assertNotFound();
        $this->getJson('/api/v1/pages/missing')->assertNotFound();
    }
}
