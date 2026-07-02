<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\FixtureResource;
use App\Http\Resources\PlayerResource;
use App\Http\Resources\TeamResource;
use App\Models\Fixture;
use App\Models\Team;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TeamController extends Controller
{
    public function show(Team $team): JsonResponse
    {
        return $this->ok(new TeamResource($team->load('venue')));
    }

    public function fixtures(Request $request, Team $team): JsonResponse
    {
        $fixtures = Fixture::query()
            ->where(fn ($q) => $q->where('home_team_id', $team->id)->orWhere('away_team_id', $team->id))
            ->when($request->filled('status_group'), fn ($q) => $q->where('status_group', $request->string('status_group')))
            ->with(['league', 'homeTeam', 'awayTeam', 'venue'])
            ->orderBy('match_datetime')
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok(FixtureResource::collection($fixtures));
    }

    public function squad(Team $team): JsonResponse
    {
        $players = $team->players()
            ->wherePivot('is_active', true)
            ->orderByPivot('number')
            ->get();

        return $this->ok(PlayerResource::collection($players));
    }
}
