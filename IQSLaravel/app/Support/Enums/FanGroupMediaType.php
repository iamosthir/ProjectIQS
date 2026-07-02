<?php

namespace App\Support\Enums;

enum FanGroupMediaType: string
{
    case Image = 'image';
    case Video = 'video';

    /**
     * Per-type archive limit (§5.1: ≤100 photos, ≤30 videos).
     */
    public function limit(): int
    {
        return match ($this) {
            self::Image => 100,
            self::Video => 30,
        };
    }
}
