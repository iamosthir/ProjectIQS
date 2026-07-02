<?php

namespace App\Support\Enums;

/**
 * The two separate comment feeds on a fixture: the Loyal-Fans match feed and
 * the predictions-page feed.
 */
enum CommentContext: string
{
    case Match = 'match';
    case Prediction = 'prediction';
}
