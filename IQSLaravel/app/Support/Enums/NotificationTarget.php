<?php

namespace App\Support\Enums;

enum NotificationTarget: string
{
    case All = 'all';
    case ClubSupporters = 'club_supporters';
    case Governorate = 'governorate';
    case Custom = 'custom';
}
