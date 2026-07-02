<?php

namespace App\Support\Enums;

enum ListingMediaType: string
{
    case Image = 'image';
    case Video = 'video';
    case Document = 'document';
}
