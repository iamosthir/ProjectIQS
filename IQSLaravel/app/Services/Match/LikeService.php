<?php

namespace App\Services\Match;

use App\Models\Like;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;

/**
 * Toggles polymorphic likes. Counter maintenance is handled by LikeObserver,
 * so callers only create/delete the Like row.
 */
class LikeService
{
    public function like(User $user, Model $likeable): void
    {
        Like::firstOrCreate([
            'user_id' => $user->id,
            'likeable_type' => $likeable->getMorphClass(),
            'likeable_id' => $likeable->getKey(),
        ]);
    }

    public function unlike(User $user, Model $likeable): void
    {
        // Fetch + delete (not a mass delete) so the observer decrements the counter.
        $this->query($user, $likeable)->first()?->delete();
    }

    public function likedBy(User $user, Model $likeable): bool
    {
        return $this->query($user, $likeable)->exists();
    }

    /**
     * @return \Illuminate\Database\Eloquent\Builder<Like>
     */
    protected function query(User $user, Model $likeable)
    {
        return Like::query()
            ->where('user_id', $user->id)
            ->where('likeable_type', $likeable->getMorphClass())
            ->where('likeable_id', $likeable->getKey());
    }
}
