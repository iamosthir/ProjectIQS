<?php

namespace App\Support;

/**
 * Resolves a translatable `*_ar`/`*_en` pair for the active locale, falling
 * back to the other language when one side is empty (§0.6).
 */
class Localize
{
    public static function pick(?string $ar, ?string $en): ?string
    {
        if (app()->getLocale() === 'ar') {
            return ($ar !== null && $ar !== '') ? $ar : $en;
        }

        return ($en !== null && $en !== '') ? $en : $ar;
    }
}
