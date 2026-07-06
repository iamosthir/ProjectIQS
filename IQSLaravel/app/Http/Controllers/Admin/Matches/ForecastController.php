<?php

namespace App\Http\Controllers\Admin\Matches;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\Matches\FixtureForecastRequest;
use App\Models\Fixture;
use App\Support\Enums\Source;
use Illuminate\Http\JsonResponse;

/**
 * One editorial forecast per fixture (API-Football "predictions"), managed
 * as an upsertable singleton nested under the fixture.
 */
class ForecastController extends Controller
{
    public function show(Fixture $fixture): JsonResponse
    {
        return $this->ok($fixture->forecast?->load('winnerTeam'));
    }

    public function upsert(FixtureForecastRequest $request, Fixture $fixture): JsonResponse
    {
        $forecast = $fixture->forecast()->updateOrCreate(
            ['fixture_id' => $fixture->id],
            array_merge($request->validated(), ['source' => Source::Manual]),
        );

        return $this->ok($forecast->load('winnerTeam'), __('Forecast saved.'));
    }

    public function destroy(Fixture $fixture): JsonResponse
    {
        $fixture->forecast?->delete();

        return $this->noContentMessage(__('Forecast deleted.'));
    }
}
