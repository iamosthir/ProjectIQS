<?php

namespace App\Models;

use App\Observers\FixturePredictionObserver;
use App\Support\Enums\PredictionOutcome;
use Illuminate\Database\Eloquent\Attributes\ObservedBy;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphMany;

#[ObservedBy([FixturePredictionObserver::class])]
class FixturePrediction extends Model
{
    /** @use HasFactory<\Database\Factories\FixturePredictionFactory> */
    use HasFactory;

    /**
     * @var list<string>
     */
    protected $fillable = [
        'fixture_id', 'user_id', 'predicted_home_score', 'predicted_away_score',
        'predicted_outcome', 'is_correct', 'is_exact_score', 'likes_count',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'predicted_home_score' => 'integer',
            'predicted_away_score' => 'integer',
            'predicted_outcome' => PredictionOutcome::class,
            'is_correct' => 'boolean',
            'is_exact_score' => 'boolean',
            'likes_count' => 'integer',
        ];
    }

    /**
     * @return BelongsTo<Fixture, $this>
     */
    public function fixture(): BelongsTo
    {
        return $this->belongsTo(Fixture::class);
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * @return MorphMany<Like, $this>
     */
    public function likes(): MorphMany
    {
        return $this->morphMany(Like::class, 'likeable');
    }

    /**
     * @return MorphMany<Comment, $this>
     */
    public function comments(): MorphMany
    {
        return $this->morphMany(Comment::class, 'commentable');
    }
}
