<?php

namespace App\Support\Enums;

/**
 * Origin of a canonical row (§0.9). `manual` rows are never overwritten by sync.
 */
enum Source: string
{
    case ApiFootball = 'api_football';
    case Manual = 'manual';
}
