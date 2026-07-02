<?php

namespace App\Support\Enums;

enum ListingStatus: string
{
    case Draft = 'draft';
    case PendingPayment = 'pending_payment';
    case PendingReview = 'pending_review';
    case Published = 'published';
    case Rejected = 'rejected';
    case Expired = 'expired';
    case Suspended = 'suspended';
}
