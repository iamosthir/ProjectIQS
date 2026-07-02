<?php

namespace App\Services\FanGroups;

use App\Models\FanGroup;
use App\Models\FanGroupChant;
use App\Models\FanGroupDocument;
use App\Models\FanGroupMedia;
use App\Support\Enums\FanGroupMediaType;
use Illuminate\Validation\ValidationException;

/**
 * Adds to a fan group's archives, enforcing the §5.1 hard limits
 * (≤100 photos, ≤30 videos, ≤20 chants) with clear 422 messages.
 */
class FanGroupArchiveService
{
    public const CHANT_LIMIT = 20;

    /**
     * @param  array<string, mixed>  $data
     */
    public function addMedia(FanGroup $group, array $data): FanGroupMedia
    {
        $type = FanGroupMediaType::from($data['type']);
        $count = $group->media()->where('type', $type->value)->count();

        if ($count >= $type->limit()) {
            throw ValidationException::withMessages([
                'type' => [__('The :type archive is full (max :max).', ['type' => $type->value, 'max' => $type->limit()])],
            ]);
        }

        return $group->media()->create($data);
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public function addChant(FanGroup $group, array $data): FanGroupChant
    {
        if ($group->chants()->count() >= self::CHANT_LIMIT) {
            throw ValidationException::withMessages([
                'video_path' => [__('The chants archive is full (max :max).', ['max' => self::CHANT_LIMIT])],
            ]);
        }

        return $group->chants()->create($data);
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public function addDocument(FanGroup $group, array $data): FanGroupDocument
    {
        return $group->documents()->create($data);
    }
}
