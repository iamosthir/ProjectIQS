<?php

namespace App\Support\Enums;

enum PaymentGatewayType: string
{
    case ZainCash = 'zaincash';
    case Fib = 'fib';
    case Manual = 'manual';
}
