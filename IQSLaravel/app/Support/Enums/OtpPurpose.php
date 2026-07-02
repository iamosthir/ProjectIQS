<?php

namespace App\Support\Enums;

enum OtpPurpose: string
{
    case Login = 'login';
    case Register = 'register';
    case ChangePhone = 'change_phone';
}
