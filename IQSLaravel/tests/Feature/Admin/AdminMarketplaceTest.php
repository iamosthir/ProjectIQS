<?php

namespace Tests\Feature\Admin;

use App\Models\Admin;
use App\Models\Listing;
use App\Models\Store;
use App\Support\Enums\ListingStatus;
use Database\Seeders\RolesPermissionsSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminMarketplaceTest extends TestCase
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

    public function test_admin_can_create_a_category(): void
    {
        $this->actingAs($this->superAdmin(), 'web')
            ->postJson('/admin/api/v1/marketplace/categories', [
                'key' => 'physio', 'name_ar' => 'أخصائي علاج', 'name_en' => 'Physiotherapist', 'base_price' => 25000,
            ])
            ->assertCreated()
            ->assertJsonPath('data.key', 'physio');
    }

    public function test_admin_can_verify_a_store(): void
    {
        $store = Store::factory()->pending()->create();

        $this->actingAs($this->superAdmin(), 'web')
            ->postJson("/admin/api/v1/marketplace/stores/{$store->id}/verify")
            ->assertOk()
            ->assertJsonPath('data.is_verified', true)
            ->assertJsonPath('data.status', 'active');
    }

    public function test_admin_can_approve_a_pending_review_listing(): void
    {
        $listing = Listing::factory()->status(ListingStatus::PendingReview)->create();

        $this->actingAs($this->superAdmin(), 'web')
            ->postJson("/admin/api/v1/marketplace/listings/{$listing->id}/approve")
            ->assertOk()
            ->assertJsonPath('data.status', 'published');

        $this->assertNotNull($listing->fresh()->published_at);
    }

    public function test_admin_cannot_approve_a_listing_still_awaiting_payment(): void
    {
        $listing = Listing::factory()->status(ListingStatus::PendingPayment)->create();

        $this->actingAs($this->superAdmin(), 'web')
            ->postJson("/admin/api/v1/marketplace/listings/{$listing->id}/approve")
            ->assertStatus(422);
    }

    public function test_admin_can_reject_with_a_reason(): void
    {
        $listing = Listing::factory()->status(ListingStatus::PendingReview)->create();
        $admin = $this->superAdmin();

        $this->actingAs($admin, 'web')
            ->postJson("/admin/api/v1/marketplace/listings/{$listing->id}/reject", ['reason' => 'Incomplete profile'])
            ->assertOk()
            ->assertJsonPath('data.status', 'rejected');

        $this->actingAs($admin, 'web')
            ->postJson("/admin/api/v1/marketplace/listings/{$listing->id}/reject", [])
            ->assertStatus(422);
    }

    public function test_contacts_report_returns_aggregates(): void
    {
        $this->actingAs($this->superAdmin(), 'web')
            ->getJson('/admin/api/v1/marketplace/contacts/report')
            ->assertOk()
            ->assertJsonStructure(['data' => ['total', 'by_type', 'top_listings']]);
    }

    public function test_marketplace_requires_permission(): void
    {
        $support = Admin::factory()->create();
        $support->assignRole('support');

        $this->actingAs($support, 'web')
            ->getJson('/admin/api/v1/marketplace/categories')
            ->assertStatus(403);
    }
}
