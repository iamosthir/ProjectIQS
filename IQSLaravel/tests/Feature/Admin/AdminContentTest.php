<?php

namespace Tests\Feature\Admin;

use App\Models\Admin;
use App\Models\Banner;
use App\Models\Page;
use Database\Seeders\RolesPermissionsSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminContentTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RolesPermissionsSeeder::class);
    }

    private function superAdmin(): Admin
    {
        $admin = Admin::factory()->create();
        $admin->assignRole('super-admin');

        return $admin;
    }

    public function test_admin_can_crud_banners(): void
    {
        $admin = $this->superAdmin();

        $created = $this->actingAs($admin, 'web')
            ->postJson('/admin/api/v1/banners', [
                'title_ar' => 'بانر', 'title_en' => 'Banner',
                'image_path' => 'banners/x.jpg',
                'action_type' => 'url', 'action_value' => 'https://iqs.iq',
                'placement' => 'home_top', 'position' => 3,
            ])
            ->assertCreated()
            ->json('data.id');

        $this->assertDatabaseHas('banners', ['id' => $created, 'placement' => 'home_top']);

        $this->actingAs($admin, 'web')
            ->putJson("/admin/api/v1/banners/{$created}", ['is_active' => false])
            ->assertOk()
            ->assertJsonPath('data.is_active', false);

        $this->actingAs($admin, 'web')
            ->getJson('/admin/api/v1/banners')
            ->assertOk()
            ->assertJsonCount(1, 'data');

        $this->actingAs($admin, 'web')
            ->deleteJson("/admin/api/v1/banners/{$created}")
            ->assertOk();

        $this->assertDatabaseMissing('banners', ['id' => $created]);
    }

    public function test_banner_validation_rejects_bad_enum(): void
    {
        $this->actingAs($this->superAdmin(), 'web')
            ->postJson('/admin/api/v1/banners', [
                'image_path' => 'banners/x.jpg',
                'action_type' => 'none',
                'placement' => 'nowhere',
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['placement']);
    }

    public function test_admin_can_crud_pages(): void
    {
        $admin = $this->superAdmin();

        $id = $this->actingAs($admin, 'web')
            ->postJson('/admin/api/v1/pages', [
                'slug' => 'faq', 'title_ar' => 'الأسئلة', 'title_en' => 'FAQ',
                'content_ar' => 'محتوى', 'content_en' => 'Content',
            ])
            ->assertCreated()
            ->json('data.id');

        $this->actingAs($admin, 'web')
            ->putJson("/admin/api/v1/pages/{$id}", ['title_en' => 'Frequently Asked'])
            ->assertOk()
            ->assertJsonPath('data.title_en', 'Frequently Asked');

        $this->actingAs($admin, 'web')
            ->deleteJson("/admin/api/v1/pages/{$id}")
            ->assertOk();

        $this->assertDatabaseMissing('pages', ['id' => $id]);
    }

    public function test_page_slug_must_be_unique(): void
    {
        Page::factory()->create(['slug' => 'about']);

        $this->actingAs($this->superAdmin(), 'web')
            ->postJson('/admin/api/v1/pages', [
                'slug' => 'about', 'title_ar' => 'ع', 'title_en' => 'A',
                'content_ar' => 'م', 'content_en' => 'C',
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['slug']);
    }

    public function test_banners_require_the_manage_banners_permission(): void
    {
        $support = Admin::factory()->create();
        $support->assignRole('support');

        $this->actingAs($support, 'web')
            ->getJson('/admin/api/v1/banners')
            ->assertStatus(403);
    }

    public function test_pages_require_the_manage_settings_permission(): void
    {
        $support = Admin::factory()->create();
        $support->assignRole('support');

        $this->actingAs($support, 'web')
            ->getJson('/admin/api/v1/pages')
            ->assertStatus(403);
    }
}
