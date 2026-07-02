<?php

namespace App\Support\Enums;

enum ClubStatus: string
{
    case Pending = 'pending';
    case Active = 'active';
    case Suspended = 'suspended';
}
