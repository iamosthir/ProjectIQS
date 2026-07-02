<?php

namespace App\Observers;

use App\Models\Comment;
use App\Models\Fixture;

/**
 * Maintains fixture `comments_count` (top-level match comments) and a parent
 * comment's `replies_count`.
 */
class CommentObserver
{
    public function created(Comment $comment): void
    {
        if ($comment->parent_id !== null) {
            Comment::whereKey($comment->parent_id)->increment('replies_count');

            return;
        }

        if ($comment->commentable_type === Fixture::class) {
            Fixture::whereKey($comment->commentable_id)->increment('comments_count');
        }
    }

    public function deleted(Comment $comment): void
    {
        if ($comment->parent_id !== null) {
            Comment::whereKey($comment->parent_id)->where('replies_count', '>', 0)->decrement('replies_count');

            return;
        }

        if ($comment->commentable_type === Fixture::class) {
            Fixture::whereKey($comment->commentable_id)->where('comments_count', '>', 0)->decrement('comments_count');
        }
    }
}
