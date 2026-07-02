<?php

namespace App\Http\Controllers\Admin\Marketplace;

use App\Http\Controllers\Controller;
use App\Http\Resources\Admin\ListingAdminResource;
use App\Models\Listing;
use App\Models\ListingContact;
use App\Services\Marketplace\ListingService;
use App\Support\Enums\ListingStatus;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Spatie\QueryBuilder\AllowedFilter;
use Spatie\QueryBuilder\QueryBuilder;

class ListingController extends Controller
{
    public function __construct(private readonly ListingService $listings) {}

    public function index(Request $request): JsonResponse
    {
        $listings = QueryBuilder::for(Listing::class)
            ->allowedFilters([
                AllowedFilter::exact('status'),
                AllowedFilter::exact('category_id'),
                AllowedFilter::exact('governorate'),
                AllowedFilter::callback('search', fn ($q, $v) => $q->where(fn ($w) => $w
                    ->where('title_ar', 'like', "%{$v}%")
                    ->orWhere('title_en', 'like', "%{$v}%")
                    ->orWhere('full_name', 'like', "%{$v}%"))),
            ])
            ->allowedSorts(['created_at', 'published_at'])
            ->defaultSort('-created_at')
            ->with(['category', 'store', 'user', 'payment'])
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok(ListingAdminResource::collection($listings));
    }

    public function show(Listing $listing): JsonResponse
    {
        return $this->ok(new ListingAdminResource(
            $listing->load(['category', 'store', 'user', 'payment', 'media', 'reviewedBy'])
        ));
    }

    public function approve(Request $request, Listing $listing): JsonResponse
    {
        // A paid listing only reaches pending_review after its payment is paid.
        if ($listing->status !== ListingStatus::PendingReview) {
            return $this->fail(__('Only listings pending review can be approved.'), null, 422);
        }

        $this->listings->approve($listing, $request->user());

        return $this->ok(new ListingAdminResource($listing->load('category')), __('Listing approved.'));
    }

    public function reject(Request $request, Listing $listing): JsonResponse
    {
        $data = $request->validate(['reason' => ['required', 'string', 'max:500']]);
        $this->listings->reject($listing, $request->user(), $data['reason']);

        return $this->ok(new ListingAdminResource($listing->load('category')), __('Listing rejected.'));
    }

    public function feature(Request $request, Listing $listing): JsonResponse
    {
        $days = $request->integer('days', 30);
        $this->listings->feature($listing, $days > 0 ? $days : null);

        return $this->ok(new ListingAdminResource($listing->load('category')), __('Listing featured.'));
    }

    /**
     * Contact-leakage analytics (§3.5 monetization decision support).
     */
    public function contactsReport(): JsonResponse
    {
        return $this->ok([
            'total' => ListingContact::count(),
            'by_type' => ListingContact::query()
                ->selectRaw('contact_type, count(*) as total')
                ->groupBy('contact_type')
                ->pluck('total', 'contact_type'),
            'top_listings' => Listing::query()
                ->where('contacts_count', '>', 0)
                ->orderByDesc('contacts_count')
                ->limit(10)
                ->get(['id', 'title_ar', 'title_en', 'contacts_count']),
        ]);
    }
}
