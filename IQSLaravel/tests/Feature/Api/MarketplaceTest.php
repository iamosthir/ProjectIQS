<?php

namespace Tests\Feature\Api;

use App\Models\Listing;
use App\Models\MarketplaceCategory;
use App\Models\Setting;
use App\Models\Store;
use App\Models\User;
use App\Support\Enums\SettingType;
use App\Support\Jwt;
use Database\Seeders\MarketplaceCategoriesSeeder;
use Database\Seeders\RolesPermissionsSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class MarketplaceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RolesPermissionsSeeder::class);
    }

    private function seller(): User
    {
        $user = User::factory()->create();
        Store::factory()->create(['user_id' => $user->id]);

        return $user;
    }

    public function test_category_tree_is_returned(): void
    {
        $this->seed(MarketplaceCategoriesSeeder::class);
        $this->actingAs(User::factory()->create(), 'sanctum');

        $this->getJson('/api/v1/marketplace/categories')
            ->assertOk()
            ->assertJsonPath('data.0.name', fn ($name) => is_string($name));
    }

    public function test_creating_a_first_store_grants_the_seller_role(): void
    {
        $user = User::factory()->create();
        $this->actingAs($user, 'sanctum');

        $this->postJson('/api/v1/marketplace/stores', ['name_ar' => 'متجري'])
            ->assertCreated();

        $this->assertTrue($user->fresh()->hasRole('seller'));
        $this->assertDatabaseHas('stores', ['user_id' => $user->id]);
    }

    public function test_paid_listing_starts_pending_payment_and_free_starts_pending_review(): void
    {
        $user = $this->seller();
        $this->actingAs($user, 'sanctum');

        $paid = MarketplaceCategory::factory()->create();
        $this->postJson('/api/v1/marketplace/listings', ['category_id' => $paid->id, 'title_ar' => 'لاعب محترف'])
            ->assertCreated()
            ->assertJsonPath('data.status', 'pending_payment');

        $free = MarketplaceCategory::factory()->free()->create();
        $this->postJson('/api/v1/marketplace/listings', ['category_id' => $free->id, 'title_ar' => 'بطاقة مجانية'])
            ->assertCreated()
            ->assertJsonPath('data.status', 'pending_review');
    }

    public function test_payment_advances_a_paid_listing_to_pending_review(): void
    {
        config([
            'services.zaincash.secret' => 'sec', 'services.zaincash.base_url' => 'https://test.zaincash.iq',
            'services.zaincash.merchant_id' => 'M', 'services.zaincash.msisdn' => '964', 'services.zaincash.redirect_url' => 'https://r',
        ]);
        Http::fake(['*transaction/init*' => Http::response(['id' => 'TX1'], 200)]);

        $user = $this->seller();
        $this->actingAs($user, 'sanctum');
        $category = MarketplaceCategory::factory()->create(['base_price' => 20000]);
        $listing = $user->listings()->create([
            'store_id' => $user->store->id, 'category_id' => $category->id,
            'title_ar' => 'لاعب', 'status' => 'pending_payment',
        ]);

        $number = $this->postJson('/api/v1/payments/initiate', [
            'payable_type' => 'listing', 'payable_id' => $listing->id, 'gateway' => 'zaincash',
        ])->assertCreated()->json('data.payment_number');

        $token = Jwt::encode(['status' => 'success', 'orderid' => $number], 'sec');
        $this->postJson('/api/v1/payments/zaincash/callback', ['token' => $token])->assertOk();

        $listing->refresh();
        $this->assertSame('pending_review', $listing->status->value);
        $this->assertNotNull($listing->payment_id);
    }

    public function test_required_field_schema_fields_are_enforced(): void
    {
        $user = $this->seller();
        $this->actingAs($user, 'sanctum');
        $category = MarketplaceCategory::factory()->create([
            'field_schema' => ['fields' => [['key' => 'position', 'required' => true]], 'media' => ['image' => 6]],
        ]);

        $this->postJson('/api/v1/marketplace/listings', ['category_id' => $category->id, 'title_ar' => 'لاعب', 'attributes' => []])
            ->assertStatus(422)
            ->assertJsonValidationErrors('attributes.position');

        $this->postJson('/api/v1/marketplace/listings', [
            'category_id' => $category->id, 'title_ar' => 'لاعب', 'attributes' => ['position' => 'GK'],
        ])->assertCreated();
    }

    public function test_contact_endpoint_respects_mode_and_logs(): void
    {
        $listing = Listing::factory()->published()->create([
            'show_contact' => true, 'contact_phone' => '+9647700000000',
        ]);
        $listing->category->update(['requires_contact_button' => true]);

        $this->actingAs(User::factory()->create(), 'sanctum');

        $this->postJson("/api/v1/marketplace/listings/{$listing->id}/contact", ['type' => 'phone'])
            ->assertOk()
            ->assertJsonPath('data.available', true)
            ->assertJsonPath('data.phone', '+9647700000000');

        $this->assertDatabaseHas('listing_contacts', ['listing_id' => $listing->id, 'contact_type' => 'phone']);

        // Commission mode hides contact (broker via platform).
        Setting::set('marketplace', 'mode', 'commission', SettingType::String);
        $this->postJson("/api/v1/marketplace/listings/{$listing->id}/contact", ['type' => 'phone'])
            ->assertOk()
            ->assertJsonPath('data.available', false);
    }

    public function test_media_limit_is_enforced_per_category(): void
    {
        Storage::fake('public');
        $user = $this->seller();
        $this->actingAs($user, 'sanctum');
        $category = MarketplaceCategory::factory()->create([
            'field_schema' => ['fields' => [], 'media' => ['image' => 1]],
        ]);
        $listing = $user->listings()->create([
            'store_id' => $user->store->id, 'category_id' => $category->id, 'title_ar' => 'لاعب', 'status' => 'draft',
        ]);

        $this->postJson("/api/v1/marketplace/listings/{$listing->id}/media", [
            'type' => 'image', 'file' => UploadedFile::fake()->image('a.jpg'),
        ])->assertCreated();

        $this->postJson("/api/v1/marketplace/listings/{$listing->id}/media", [
            'type' => 'image', 'file' => UploadedFile::fake()->image('b.jpg'),
        ])->assertStatus(422);
    }

    public function test_listing_mutations_are_owner_gated(): void
    {
        $owner = $this->seller();
        $listing = $owner->listings()->create([
            'store_id' => $owner->store->id, 'category_id' => MarketplaceCategory::factory()->create()->id,
            'title_ar' => 'لاعب', 'status' => 'draft',
        ]);

        $this->actingAs(User::factory()->create(), 'sanctum');
        $this->putJson("/api/v1/marketplace/listings/{$listing->id}", ['title_ar' => 'hack'])->assertStatus(403);
        $this->deleteJson("/api/v1/marketplace/listings/{$listing->id}")->assertStatus(403);
    }
}
