<?php

namespace App\Support\Enums;

enum MatchWinner: string
{
    case Home = 'home';
    case Away = 'away';
    case Draw = 'draw';

    public static function fromScores(?int $home, ?int $away): ?self
    {
        if ($home === null || $away === null) {
            return null;
        }

        return match (true) {
            $home > $away => self::Home,
            $home < $away => self::Away,
            default => self::Draw,
        };
    }
}
