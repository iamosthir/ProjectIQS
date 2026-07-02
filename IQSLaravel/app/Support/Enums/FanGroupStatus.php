<?php

namespace App\Support\Enums;

enum FanGroupStatus: string
{
    case Pending = 'pending';
    case Active = 'active';
    case Suspended = 'suspended';
}
