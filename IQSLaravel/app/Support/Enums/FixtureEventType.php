<?php

namespace App\Support\Enums;

/**
 * Fixture timeline event types (§2.1). The first four mirror API-Football;
 * the rest drive the manual match console lifecycle.
 */
enum FixtureEventType: string
{
    case Goal = 'goal';
    case Card = 'card';
    case Subst = 'subst';
    case Var = 'var';
    case Kickoff = 'kickoff';
    case HalfEnd = 'half_end';
    case Penalty = 'penalty';
    case MatchEnd = 'match_end';
    case MatchCancelled = 'match_cancelled';
    case MatchPostponed = 'match_postponed';

    /**
     * Status-changing events close the manual console and flip status_group.
     */
    public function resultingStatus(): ?FixtureStatusGroup
    {
        return match ($this) {
            self::MatchEnd => FixtureStatusGroup::Finished,
            self::MatchCancelled => FixtureStatusGroup::Cancelled,
            self::MatchPostponed => FixtureStatusGroup::Postponed,
            default => null,
        };
    }
}
