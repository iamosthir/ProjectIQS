<?php

namespace App\Support\Enums;

enum PredictionOutcome: string
{
    case Home = 'home';
    case Draw = 'draw';
    case Away = 'away';

    /**
     * Derive the outcome from a predicted/actual scoreline.
     */
    public static function fromScores(int $home, int $away): self
    {
        return match (true) {
            $home > $away => self::Home,
            $home < $away => self::Away,
            default => self::Draw,
        };
    }
}
