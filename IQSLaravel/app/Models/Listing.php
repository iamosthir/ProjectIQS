<?php

namespace App\Models;

use App\Contracts\Payable;
use App\Support\Enums\Currency;
use App\Support\Enums\ListingStatus;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Str;

class Listing extends Model implements Payable
{
    /** @use HasFactory<\Database\Factories\ListingFactory> */
    use HasFactory, SoftDeletes;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'store_id', 'user_id', 'category_id', 'title_ar', 'title_en', 'slug', 'status',
        'full_name', 'photo_path', 'date_of_birth', 'age', 'country', 'nationality',
        'governorate', 'city', 'contact_phone', 'contact_whatsapp', 'contact_email',
        'show_contact', 'attributes', 'cv_path', 'rejection_reason', 'reviewed_by',
        'reviewed_at', 'is_featured', 'featured_until', 'views_count', 'contacts_count',
        'payment_id', 'published_at', 'expires_at',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'status' => ListingStatus::class,
            'attributes' => 'array',
            'show_contact' => 'boolean',
            'is_featured' => 'boolean',
            'date_of_birth' => 'date',
            'reviewed_at' => 'datetime',
            'featured_until' => 'datetime',
            'published_at' => 'datetime',
            'expires_at' => 'datetime',
        ];
    }

    protected static function booted(): void
    {
        static::creating(function (Listing $listing): void {
            $listing->slug ??= Str::slug(Str::limit($listing->title_en ?: $listing->title_ar, 40, '')).'-'.Str::random(6);
        });
    }

    /**
     * Stored age, or computed from the date of birth when absent.
     *
     * @return Attribute<int|null, never>
     */
    protected function age(): Attribute
    {
        return Attribute::make(
            get: fn (?int $value) => $value ?? $this->date_of_birth?->age,
        );
    }

    // --- Payable (§6) ---

    public function getPaymentAmount(): float
    {
        $this->loadMissing('category');

        return (float) ($this->category?->base_price ?? 0);
    }

    public function getPaymentCurrency(): Currency
    {
        $this->loadMissing('category');

        return $this->category?->currency ?? Currency::IQD;
    }

    public function getPaymentDescription(): string
    {
        return $this->title_en ?: $this->title_ar;
    }

    public function getPayerId(): int
    {
        return (int) $this->user_id;
    }

    public function onPaymentPaid(Payment $payment): void
    {
        if ($this->status === ListingStatus::PendingPayment) {
            $this->forceFill([
                'status' => ListingStatus::PendingReview,
                'payment_id' => $payment->id,
            ])->save();
        }
    }

    // --- Relationships ---

    /**
     * @return BelongsTo<Store, $this>
     */
    public function store(): BelongsTo
    {
        return $this->belongsTo(Store::class);
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * @return BelongsTo<MarketplaceCategory, $this>
     */
    public function category(): BelongsTo
    {
        return $this->belongsTo(MarketplaceCategory::class, 'category_id');
    }

    /**
     * @return BelongsTo<Payment, $this>
     */
    public function payment(): BelongsTo
    {
        return $this->belongsTo(Payment::class);
    }

    /**
     * @return BelongsTo<Admin, $this>
     */
    public function reviewedBy(): BelongsTo
    {
        return $this->belongsTo(Admin::class, 'reviewed_by');
    }

    /**
     * @return HasMany<ListingMedia, $this>
     */
    public function media(): HasMany
    {
        return $this->hasMany(ListingMedia::class)->orderBy('display_order');
    }

    /**
     * @return HasMany<ListingContact, $this>
     */
    public function contacts(): HasMany
    {
        return $this->hasMany(ListingContact::class);
    }
}
