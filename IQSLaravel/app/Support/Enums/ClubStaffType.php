<?php

namespace App\Support\Enums;

enum ClubStaffType: string
{
    case Coaching = 'coaching';
    case Technical = 'technical';
    case Medical = 'medical';
    case Admin = 'admin';
}
