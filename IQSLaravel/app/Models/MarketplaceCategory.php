<?php

namespace App\Models;

use App\Support\Enums\Currency;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class MarketplaceCategory extends Model
{
    /** @use HasFactory<\Database\Factories\MarketplaceCategoryFactory> */
    use HasFactory;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'key', 'parent_id', 'name_ar', 'name_en', 'description_ar', 'description_en',
        'icon_path', 'base_price', 'currency', 'is_free', 'pricing_note',
        'field_schema', 'requires_contact_button', 'listing_duration_days',
        'display_order', 'is_active',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'currency' => Currency::class,
            'base_price' => 'decimal:2',
            'is_free' => 'boolean',
            'requires_contact_button' => 'boolean',
            'is_active' => 'boolean',
            'field_schema' => 'array',
        ];
    }

    /**
     * Per-type media limits declared in field_schema['media'] (defaults applied).
     *
     * @return array<string, int>
     */
    public function mediaLimits(): array
    {
        $limits = $this->field_schema['media'] ?? [];

        return [
            'image' => (int) ($limits['image'] ?? 6),
            'video' => (int) ($limits['video'] ?? 1),
            'document' => (int) ($limits['document'] ?? 1),
        ];
    }

    /**
     * @return BelongsTo<MarketplaceCategory, $this>
     */
    public function parent(): BelongsTo
    {
        return $this->belongsTo(MarketplaceCategory::class, 'parent_id');
    }

    /**
     * @return HasMany<MarketplaceCategory, $this>
     */
    public function children(): HasMany
    {
        return $this->hasMany(MarketplaceCategory::class, 'parent_id');
    }

    /**
     * @return HasMany<Listing, $this>
     */
    public function listings(): HasMany
    {
        return $this->hasMany(Listing::class, 'category_id');
    }
}
