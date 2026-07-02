<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\CommentResource;
use App\Models\Comment;
use App\Models\Fixture;
use App\Models\Like;
use App\Models\User;
use App\Services\Match\LikeService;
use App\Support\Enums\CommentContext;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class CommentController extends Controller
{
    public function __construct(private readonly LikeService $likes) {}

    /**
     * Top-level comments for a fixture feed (context = match | prediction).
     */
    public function index(Request $request, Fixture $fixture): JsonResponse
    {
        $context = $request->string('context', 'match');

        $query = $fixture->comments()
            ->whereNull('parent_id')
            ->where('is_hidden', false)
            ->where('context', $context)
            ->with('user');

        match ($request->string('sort', 'newest')->value()) {
            'most_liked' => $query->orderByDesc('likes_count'),
            'most_replied' => $query->orderByDesc('replies_count'),
            'oldest' => $query->orderBy('created_at'),
            default => $query->orderByDesc('created_at'),
        };

        $comments = $query->paginate($this->perPage($request))->appends($request->query());
        $this->markLiked($comments->getCollection(), $request->user());

        return $this->ok(CommentResource::collection($comments));
    }

    public function store(Request $request, Fixture $fixture): JsonResponse
    {
        $data = $request->validate([
            'body' => ['required', 'string', 'max:2000'],
            'context' => ['sometimes', Rule::enum(CommentContext::class)],
            'parent_id' => ['sometimes', 'nullable', 'integer', 'exists:comments,id'],
        ]);

        $comment = $fixture->comments()->create([
            'user_id' => $request->user()->id,
            'context' => $data['context'] ?? CommentContext::Match->value,
            'parent_id' => $data['parent_id'] ?? null,
            'body' => $data['body'],
        ]);

        return $this->created(new CommentResource($comment->load('user')), __('Comment added.'));
    }

    public function replies(Request $request, Comment $comment): JsonResponse
    {
        $replies = $comment->replies()
            ->where('is_hidden', false)
            ->with('user')
            ->orderBy('created_at')
            ->paginate($this->perPage($request))
            ->appends($request->query());

        $this->markLiked($replies->getCollection(), $request->user());

        return $this->ok(CommentResource::collection($replies));
    }

    public function update(Request $request, Comment $comment): JsonResponse
    {
        abort_unless($comment->user_id === $request->user()->id, 403, __('You can only edit your own comment.'));

        $data = $request->validate(['body' => ['required', 'string', 'max:2000']]);
        $comment->update(['body' => $data['body']]);

        return $this->ok(new CommentResource($comment->load('user')), __('Comment updated.'));
    }

    public function destroy(Request $request, Comment $comment): JsonResponse
    {
        abort_unless($comment->user_id === $request->user()->id, 403, __('You can only delete your own comment.'));

        $comment->delete();

        return $this->noContentMessage(__('Comment deleted.'));
    }

    public function like(Request $request, Comment $comment): JsonResponse
    {
        $this->likes->like($request->user(), $comment);

        return $this->ok(['likes_count' => $comment->fresh()->likes_count], __('Liked.'));
    }

    public function unlike(Request $request, Comment $comment): JsonResponse
    {
        $this->likes->unlike($request->user(), $comment);

        return $this->ok(['likes_count' => $comment->fresh()->likes_count], __('Unliked.'));
    }

    /**
     * Flag which comments in the set the caller has liked.
     *
     * @param  Collection<int, Comment>  $comments
     */
    protected function markLiked(Collection $comments, User $user): void
    {
        if ($comments->isEmpty()) {
            return;
        }

        $liked = Like::query()
            ->where('user_id', $user->id)
            ->where('likeable_type', (new Comment)->getMorphClass())
            ->whereIn('likeable_id', $comments->pluck('id'))
            ->pluck('likeable_id')
            ->all();

        foreach ($comments as $comment) {
            $comment->setAttribute('liked_by_me', in_array($comment->id, $liked, true));
        }
    }
}
