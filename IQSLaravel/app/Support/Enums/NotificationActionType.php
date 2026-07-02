<?php

namespace App\Support\Enums;

enum NotificationActionType: string
{
    case None = 'none';
    case Url = 'url';
    case Fixture = 'fixture';
    case Listing = 'listing';
    case Club = 'club';
    case FanGroup = 'fan_group';
}
