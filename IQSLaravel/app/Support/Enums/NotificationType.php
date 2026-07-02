<?php

namespace App\Support\Enums;

enum NotificationType: string
{
    case General = 'general';
    case Match = 'match';
    case Goal = 'goal';
    case Listing = 'listing';
    case Club = 'club';
    case FanGroup = 'fan_group';
    case Payment = 'payment';
    case System = 'system';
}
