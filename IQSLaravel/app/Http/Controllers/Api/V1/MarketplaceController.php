<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Marketplace\ListingMediaRequest;
use App\Http\Requests\Api\Marketplace\StoreListingRequest;
use App\Http\Requests\Api\Marketplace\StoreStoreRequest;
use App\Http\Requests\Api\Marketplace\UpdateListingRequest;
use App\Http\Resources\ListingMediaResource;
use App\Http\Resources\ListingResource;
use App\Http\Resources\MarketplaceCategoryResource;
use App\Http\Resources\StoreResource;
use App\Models\Listing;
use App\Models\ListingContact;
use App\Models\MarketplaceCategory;
use App\Models\Setting;
use App\Models\Store;
use App\Services\Marketplace\ListingService;
use App\Support\Enums\ListingStatus;
use App\Support\Enums\StoreStatus;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MarketplaceController extends Controller
{
    public function __construct(private readonly ListingService $listings) {}

    public function categories(): JsonResponse
    {
        $categories = MarketplaceCategory::query()
            ->whereNull('parent_id')
            ->where('is_active', true)
            ->with(['children' => fn ($q) => $q->where('is_active', true)->orderBy('display_order')])
            ->orderBy('display_order')
            ->get();

        return $this->ok(MarketplaceCategoryResource::collection($categories));
    }

    public function listings(Request $request): JsonResponse
    {
        $listings = Listing::query()
            ->where('status', ListingStatus::Published)
            ->when($request->filled('category'), fn ($q) => $q->where('category_id', $request->integer('category')))
            ->when($request->filled('governorate'), fn ($q) => $q->where('governorate', $request->string('governorate')))
            ->when($request->boolean('featured'), fn ($q) => $q->where('is_featured', true))
            ->when($request->filled('q'), fn ($q) => $q->where(fn ($w) => $w
                ->where('title_ar', 'like', '%'.$request->string('q').'%')
                ->orWhere('title_en', 'like', '%'.$request->string('q').'%')
                ->orWhere('full_name', 'like', '%'.$request->string('q').'%')))
            ->with(['category', 'store', 'media'])
            ->orderByDesc('is_featured')
            ->latest('published_at')
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok(ListingResource::collection($listings));
    }

    public function showListing(Request $request, Listing $listing): JsonResponse
    {
        $isOwner = $listing->user_id === $request->user()->id;

        if ($listing->status !== ListingStatus::Published && ! $isOwner) {
            return $this->fail(__('Listing not found.'), null, 404);
        }

        $listing->increment('views_count');
        $listing->load(['category', 'store', 'media']);
        $listing->setAttribute('is_owner', $isOwner);
        $listing->setAttribute('contact_available', $this->contactAllowed($listing));

        return $this->ok(new ListingResource($listing));
    }

    public function contact(Request $request, Listing $listing): JsonResponse
    {
        $type = in_array($request->input('type'), ['phone', 'whatsapp', 'email', 'button'], true)
            ? $request->input('type') : 'button';

        ListingContact::create([
            'listing_id' => $listing->id,
            'user_id' => $request->user()->id,
            'contact_type' => $type,
            'ip_address' => $request->ip(),
        ]);
        $listing->increment('contacts_count');

        if (! $this->contactAllowed($listing)) {
            return $this->ok(['available' => false], __('Please proceed through the platform.'));
        }

        return $this->ok([
            'available' => true,
            'phone' => $listing->contact_phone,
            'whatsapp' => $listing->contact_whatsapp,
            'email' => $listing->contact_email,
        ]);
    }

    public function myStore(Request $request): JsonResponse
    {
        $store = $request->user()->store()->withCount('listings')->first();

        return $this->ok($store ? new StoreResource($store) : null);
    }

    public function createStore(StoreStoreRequest $request): JsonResponse
    {
        if ($request->user()->store()->exists()) {
            return $this->fail(__('You already have a store.'), null, 422);
        }

        $store = Store::create(array_merge($request->validated(), [
            'user_id' => $request->user()->id,
            'status' => StoreStatus::Active,
        ]));

        // First store → grant the seller capability (sanctum guard).
        $request->user()->assignRole('seller');

        return $this->created(new StoreResource($store), __('Store created.'));
    }

    public function updateStore(StoreStoreRequest $request, Store $store): JsonResponse
    {
        $this->ensureOwner($store->user_id, $request);
        $store->update($request->validated());

        return $this->ok(new StoreResource($store), __('Store updated.'));
    }

    public function myListings(Request $request): JsonResponse
    {
        $listings = $request->user()->listings()
            ->with(['category', 'media'])
            ->latest()
            ->paginate($this->perPage($request))
            ->appends($request->query());

        $listings->getCollection()->each->setAttribute('is_owner', true);

        return $this->ok(ListingResource::collection($listings));
    }

    public function createListing(StoreListingRequest $request): JsonResponse
    {
        $store = $request->user()->store;

        if ($store === null) {
            return $this->fail(__('Create a store before posting a listing.'), null, 422);
        }

        $category = MarketplaceCategory::findOrFail($request->integer('category_id'));
        $listing = $this->listings->create($request->user(), $store, $category, $request->safe()->except('category_id'));
        $listing->setAttribute('is_owner', true);

        return $this->created(new ListingResource($listing->load('category')), __('Listing created.'));
    }

    public function updateListing(UpdateListingRequest $request, Listing $listing): JsonResponse
    {
        $this->ensureOwner($listing->user_id, $request);
        $this->listings->update($listing, $request->validated());
        $listing->setAttribute('is_owner', true);

        return $this->ok(new ListingResource($listing->load('category')), __('Listing updated.'));
    }

    public function deleteListing(Request $request, Listing $listing): JsonResponse
    {
        $this->ensureOwner($listing->user_id, $request);
        $listing->delete();

        return $this->noContentMessage(__('Listing deleted.'));
    }

    public function uploadMedia(ListingMediaRequest $request, Listing $listing): JsonResponse
    {
        $this->ensureOwner($listing->user_id, $request);

        $type = $request->string('type')->value();
        $limit = $listing->category->mediaLimits()[$type] ?? 0;

        if ($listing->media()->where('type', $type)->count() >= $limit) {
            return $this->fail(__('Media limit reached for this type.'), null, 422);
        }

        $file = $request->file('file');
        $path = $file->store("listings/{$listing->id}", 'public');

        $media = $listing->media()->create([
            'type' => $type,
            'path' => $path,
            'title' => $request->input('title'),
            'mime_type' => $file->getMimeType(),
            'size' => $file->getSize(),
            'display_order' => $listing->media()->count(),
        ]);

        return $this->created(new ListingMediaResource($media), __('Media uploaded.'));
    }

    protected function contactAllowed(Listing $listing): bool
    {
        if (Setting::get('marketplace', 'mode', 'contact') === 'commission') {
            return false;
        }

        $listing->loadMissing('category');

        return $listing->show_contact && (bool) $listing->category?->requires_contact_button;
    }

    protected function ensureOwner(int $ownerId, Request $request): void
    {
        abort_unless($ownerId === $request->user()->id, 403, __('This action is unauthorized.'));
    }
}
