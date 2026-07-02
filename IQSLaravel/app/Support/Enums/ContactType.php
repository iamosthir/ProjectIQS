<?php

namespace App\Support\Enums;

enum ContactType: string
{
    case Phone = 'phone';
    case Whatsapp = 'whatsapp';
    case Email = 'email';
    case Button = 'button';
}
