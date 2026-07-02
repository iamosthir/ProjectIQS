<?php

namespace App\Support\Enums;

enum VerificationMethod: string
{
    case Message = 'message';
    case Voice = 'voice';
    case Video = 'video';
}
