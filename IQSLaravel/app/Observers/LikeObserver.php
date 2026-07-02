<?php

namespace App\Observers;

use App\Models\Like;

/**
 * Keeps the polymorphic parent's `likes_count` in sync (Fixture, Comment,
 * FixturePrediction all expose the column).
 */
class LikeObserver
{
    public function created(Like $like): void
    {
        $like->likeable?->increment('likes_count');
    }

    public function deleted(Like $like): void
    {
        $likeable = $like->likeable;

        if ($likeable !== null && $likeable->likes_count > 0) {
            $likeable->decrement('likes_count');
        }
    }
}
