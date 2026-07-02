<?php

namespace App\Services\Marketplace;

use App\Models\Admin;
use App\Models\Listing;
use App\Models\MarketplaceCategory;
use App\Models\Store;
use App\Models\User;
use App\Support\Enums\ListingStatus;

/**
 * Drives the listing lifecycle (§3.4):
 * draft → pending_payment → (pay) → pending_review → published / rejected.
 * Free categories skip payment and go straight to review.
 */
class ListingService
{
    /**
     * @param  array<string, mixed>  $data
     */
    public function create(User $user, Store $store, MarketplaceCategory $category, array $data): Listing
    {
        return $store->listings()->create(array_merge($data, [
            'user_id' => $user->id,
            'category_id' => $category->id,
            'status' => $category->is_free ? ListingStatus::PendingReview : ListingStatus::PendingPayment,
        ]));
    }

    /**
     * Editing a live/finished listing sends it back through review.
     *
     * @param  array<string, mixed>  $data
     */
    public function update(Listing $listing, array $data): Listing
    {
        $listing->update($data);

        if (in_array($listing->status, [ListingStatus::Published, ListingStatus::Rejected, ListingStatus::Expired], true)) {
            $listing->update(['status' => ListingStatus::PendingReview]);
        }

        return $listing;
    }

    public function approve(Listing $listing, Admin $admin): Listing
    {
        $duration = $listing->category->listing_duration_days;

        $listing->forceFill([
            'status' => ListingStatus::Published,
            'reviewed_by' => $admin->id,
            'reviewed_at' => now(),
            'published_at' => now(),
            'expires_at' => $duration !== null ? now()->addDays($duration) : null,
            'rejection_reason' => null,
        ])->save();

        return $listing;
    }

    public function reject(Listing $listing, Admin $admin, string $reason): Listing
    {
        $listing->forceFill([
            'status' => ListingStatus::Rejected,
            'reviewed_by' => $admin->id,
            'reviewed_at' => now(),
            'rejection_reason' => $reason,
        ])->save();

        return $listing;
    }

    public function feature(Listing $listing, ?int $days = 30): Listing
    {
        $listing->forceFill([
            'is_featured' => true,
            'featured_until' => $days !== null ? now()->addDays($days) : null,
        ])->save();

        return $listing;
    }

    /**
     * Expire published listings past their window (scheduled job).
     */
    public function expireDue(): int
    {
        return Listing::query()
            ->where('status', ListingStatus::Published)
            ->whereNotNull('expires_at')
            ->where('expires_at', '<', now())
            ->update(['status' => ListingStatus::Expired]);
    }
}
