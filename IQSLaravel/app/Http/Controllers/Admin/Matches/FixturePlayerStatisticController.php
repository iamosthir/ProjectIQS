<?php

namespace App\Http\Controllers\Admin\Matches;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\Matches\FixturePlayerStatisticRequest;
use App\Models\Fixture;
use App\Models\FixturePlayerStatistic;
use App\Support\Enums\Source;
use Illuminate\Http\JsonResponse;

class FixturePlayerStatisticController extends Controller
{
    public function index(Fixture $fixture): JsonResponse
    {
        return $this->ok(
            $fixture->playerStatistics()->with(['player', 'team'])->get()
        );
    }

    public function store(FixturePlayerStatisticRequest $request, Fixture $fixture): JsonResponse
    {
        $row = $fixture->playerStatistics()->create(
            array_merge($request->validated(), ['source' => Source::Manual])
        );

        return $this->created($row->load(['player', 'team']), __('Player match statistics created.'));
    }

    public function update(FixturePlayerStatisticRequest $request, Fixture $fixture, FixturePlayerStatistic $statistic): JsonResponse
    {
        abort_unless($statistic->fixture_id === $fixture->id, 404);

        $statistic->update($request->validated());

        return $this->ok($statistic->load(['player', 'team']), __('Player match statistics updated.'));
    }

    public function destroy(Fixture $fixture, FixturePlayerStatistic $statistic): JsonResponse
    {
        abort_unless($statistic->fixture_id === $fixture->id, 404);

        $statistic->delete();

        return $this->noContentMessage(__('Player match statistics deleted.'));
    }
}
