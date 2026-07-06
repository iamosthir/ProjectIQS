<?php

namespace App\Http\Controllers\Admin\Matches;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\Matches\PlayerStatisticRequest;
use App\Models\PlayerStatistic;
use App\Support\Enums\Source;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PlayerStatisticController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $statistics = PlayerStatistic::query()
            ->with(['player', 'team', 'league', 'season'])
            ->when($request->filled('player_id'), fn ($q) => $q->where('player_id', $request->integer('player_id')))
            ->when($request->filled('team_id'), fn ($q) => $q->where('team_id', $request->integer('team_id')))
            ->when($request->filled('league_id'), fn ($q) => $q->where('league_id', $request->integer('league_id')))
            ->when($request->filled('season_id'), fn ($q) => $q->where('season_id', $request->integer('season_id')))
            ->orderByDesc('goals_total')
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok($statistics);
    }

    public function store(PlayerStatisticRequest $request): JsonResponse
    {
        $statistic = PlayerStatistic::create(array_merge($request->validated(), ['source' => Source::Manual]));

        return $this->created($statistic->load(['player', 'team', 'league', 'season']), __('Player statistics created.'));
    }

    public function show(PlayerStatistic $playerStatistic): JsonResponse
    {
        return $this->ok($playerStatistic->load(['player', 'team', 'league', 'season']));
    }

    public function update(PlayerStatisticRequest $request, PlayerStatistic $playerStatistic): JsonResponse
    {
        $playerStatistic->update($request->validated());

        return $this->ok($playerStatistic->load(['player', 'team', 'league', 'season']), __('Player statistics updated.'));
    }

    public function destroy(PlayerStatistic $playerStatistic): JsonResponse
    {
        $playerStatistic->delete();

        return $this->noContentMessage(__('Player statistics deleted.'));
    }
}
