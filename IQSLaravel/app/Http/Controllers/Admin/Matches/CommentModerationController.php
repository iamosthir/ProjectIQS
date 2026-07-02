<?php

namespace App\Http\Controllers\Admin\Matches;

use App\Http\Controllers\Controller;
use App\Http\Resources\Admin\CommentAdminResource;
use App\Models\Comment;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CommentModerationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $comments = Comment::query()
            ->when($request->filled('commentable_id'), fn ($q) => $q->where('commentable_id', $request->integer('commentable_id')))
            ->when($request->filled('context'), fn ($q) => $q->where('context', $request->string('context')))
            ->when($request->filled('hidden'), fn ($q) => $q->where('is_hidden', $request->boolean('hidden')))
            ->when($request->filled('search'), fn ($q) => $q->where('body', 'like', '%'.$request->string('search').'%'))
            ->with('user')
            ->latest()
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok(CommentAdminResource::collection($comments));
    }

    /**
     * Toggle a comment's hidden flag.
     */
    public function hide(Comment $comment): JsonResponse
    {
        $comment->update(['is_hidden' => ! $comment->is_hidden]);

        return $this->ok(['is_hidden' => $comment->is_hidden], __('Comment updated.'));
    }

    public function destroy(Comment $comment): JsonResponse
    {
        $comment->delete();

        return $this->noContentMessage(__('Comment deleted.'));
    }
}
