<?php

namespace App\Support\Enums;

/**
 * Normalized fixture status (§2.3). The app filters simply on this group,
 * while the raw API short/long codes are stored alongside.
 */
enum FixtureStatusGroup: string
{
    case Scheduled = 'scheduled';
    case Live = 'live';
    case Finished = 'finished';
    case Postponed = 'postponed';
    case Cancelled = 'cancelled';

    /**
     * Map an API-Football `status.short` code onto a normalized group.
     */
    public static function fromApiShort(?string $short): self
    {
        return match (strtoupper((string) $short)) {
            'TBD', 'NS' => self::Scheduled,
            '1H', 'HT', '2H', 'ET', 'BT', 'P', 'SUSP', 'INT', 'LIVE' => self::Live,
            'FT', 'AET', 'PEN', 'AWD', 'WO' => self::Finished,
            'PST' => self::Postponed,
            'CANC', 'ABD' => self::Cancelled,
            default => self::Scheduled,
        };
    }

    public function isLive(): bool
    {
        return $this === self::Live;
    }

    public function isFinished(): bool
    {
        return $this === self::Finished;
    }
}
