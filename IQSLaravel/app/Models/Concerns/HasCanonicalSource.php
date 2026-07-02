<?php

namespace App\Models\Concerns;

use App\Support\Enums\Source;
use Illuminate\Database\Eloquent\Builder;

/**
 * Shared behaviour for canonical entities that carry the §0.9 source columns
 * (`source`, `external_id`, `external_payload`, `last_synced_at`, `is_locked`).
 * Sync upserts on (source = api_football, external_id) and never touches
 * `manual` or `is_locked` rows.
 */
trait HasCanonicalSource
{
    public function initializeHasCanonicalSource(): void
    {
        $this->mergeCasts([
            'source' => Source::class,
            'external_payload' => 'array',
            'last_synced_at' => 'datetime',
            'is_locked' => 'boolean',
        ]);
    }

    public function isManual(): bool
    {
        return $this->source === Source::Manual;
    }

    public function isFromApi(): bool
    {
        return $this->source === Source::ApiFootball;
    }

    /**
     * Rows protected from being overwritten by sync.
     */
    public function isSyncProtected(): bool
    {
        return $this->isManual() || (bool) ($this->is_locked ?? false);
    }

    /**
     * @param  Builder<static>  $query
     */
    public function scopeApiFootball(Builder $query): void
    {
        $query->where('source', Source::ApiFootball->value);
    }

    /**
     * @param  Builder<static>  $query
     */
    public function scopeManual(Builder $query): void
    {
        $query->where('source', Source::Manual->value);
    }
}
