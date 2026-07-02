<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\BroadcastResource;
use App\Http\Resources\FixtureDetailResource;
use App\Http\Resources\FixtureEventResource;
use App\Http\Resources\FixtureNewsResource;
use App\Http\Resources\FixtureResource;
use App\Http\Resources\LineupResource;
use App\Http\Resources\StatisticResource;
use App\Models\Fixture;
use App\Services\Match\LikeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FixtureController extends Controller
{
    public function __construct(private readonly LikeService $likes) {}

    public function index(Request $request): JsonResponse
    {
        $fixtures = Fixture::query()
            ->when($request->filled('date'), fn ($q) => $q->whereDate('match_datetime', $request->date('date')))
            ->when($request->filled('league'), fn ($q) => $q->where('league_id', $request->integer('league')))
            ->when($request->filled('status_group'), fn ($q) => $q->where('status_group', $request->string('status_group')))
            ->when($request->filled('team'), function ($q) use ($request): void {
                $team = $request->integer('team');
                $q->where(fn ($w) => $w->where('home_team_id', $team)->orWhere('away_team_id', $team));
            })
            ->with(['league', 'homeTeam', 'awayTeam', 'venue'])
            ->orderBy('match_datetime')
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok(FixtureResource::collection($fixtures));
    }

    public function live(Request $request): JsonResponse
    {
        $fixtures = Fixture::query()
            ->where('status_group', 'live')
            ->with(['league', 'homeTeam', 'awayTeam', 'venue'])
            ->orderBy('match_datetime')
            ->get();

        return $this->ok(FixtureResource::collection($fixtures));
    }

    public function show(Request $request, Fixture $fixture): JsonResponse
    {
        $fixture->load([
            'league', 'homeTeam', 'awayTeam', 'venue', 'broadcasts',
            'events.player', 'events.assistPlayer',
            'lineups.team', 'lineups.coach', 'lineups.players',
            'statistics',
        ]);

        $user = $request->user();
        $fixture->setAttribute('liked_by_me', $this->likes->likedBy($user, $fixture));
        $fixture->setAttribute('my_prediction', $fixture->predictions()->where('user_id', $user->id)->first());

        return $this->ok(new FixtureDetailResource($fixture));
    }

    public function events(Fixture $fixture): JsonResponse
    {
        $fixture->load(['events.player', 'events.assistPlayer']);

        return $this->ok(FixtureEventResource::collection($fixture->events));
    }

    public function lineups(Fixture $fixture): JsonResponse
    {
        $fixture->load(['lineups.team', 'lineups.coach', 'lineups.players']);

        return $this->ok(LineupResource::collection($fixture->lineups));
    }

    public function statistics(Fixture $fixture): JsonResponse
    {
        return $this->ok(StatisticResource::collection($fixture->statistics()->orderBy('display_order')->get()));
    }

    public function broadcasts(Fixture $fixture): JsonResponse
    {
        return $this->ok(BroadcastResource::collection($fixture->broadcasts));
    }

    public function news(Request $request, Fixture $fixture): JsonResponse
    {
        $news = $fixture->news()
            ->where('is_published', true)
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok(FixtureNewsResource::collection($news));
    }

    public function like(Request $request, Fixture $fixture): JsonResponse
    {
        $this->likes->like($request->user(), $fixture);

        return $this->ok(['likes_count' => $fixture->fresh()->likes_count], __('Liked.'));
    }

    public function unlike(Request $request, Fixture $fixture): JsonResponse
    {
        $this->likes->unlike($request->user(), $fixture);

        return $this->ok(['likes_count' => $fixture->fresh()->likes_count], __('Unliked.'));
    }

    public function share(Fixture $fixture): JsonResponse
    {
        $fixture->increment('shares_count');

        return $this->ok(['shares_count' => $fixture->fresh()->shares_count], __('Shared.'));
    }
}
