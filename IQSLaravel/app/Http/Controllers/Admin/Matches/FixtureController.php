<?php

namespace App\Http\Controllers\Admin\Matches;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\Matches\FixtureRequest;
use App\Http\Resources\Admin\FixtureAdminResource;
use App\Jobs\SettleFixturePredictionsJob;
use App\Models\Fixture;
use App\Support\Enums\FixtureStatusGroup;
use App\Support\Enums\MatchWinner;
use App\Support\Enums\Source;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Spatie\QueryBuilder\AllowedFilter;
use Spatie\QueryBuilder\QueryBuilder;

class FixtureController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $fixtures = QueryBuilder::for(Fixture::class)
            ->allowedFilters([
                AllowedFilter::exact('league_id'),
                AllowedFilter::exact('season_id'),
                AllowedFilter::exact('status_group'),
                AllowedFilter::exact('source'),
                AllowedFilter::callback('date', fn ($q, $v) => $q->whereDate('match_datetime', $v)),
            ])
            ->allowedSorts(['match_datetime', 'created_at'])
            ->defaultSort('-match_datetime')
            ->with(['league', 'homeTeam', 'awayTeam'])
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok(FixtureAdminResource::collection($fixtures));
    }

    public function store(FixtureRequest $request): JsonResponse
    {
        $data = $request->validated();
        $data['source'] = Source::Manual;
        $data['status_short'] ??= 'NS';
        $data['status_group'] ??= FixtureStatusGroup::fromApiShort($data['status_short'])->value;

        $fixture = Fixture::create($data);

        return $this->created(new FixtureAdminResource($this->loaded($fixture)), __('Fixture created.'));
    }

    public function show(Fixture $fixture): JsonResponse
    {
        return $this->ok(new FixtureAdminResource($this->loaded($fixture)));
    }

    public function update(FixtureRequest $request, Fixture $fixture): JsonResponse
    {
        $data = $request->validated();

        // Auto-derive the winner from the scoreline unless explicitly set.
        if (! array_key_exists('winner', $data)
            && array_key_exists('home_goals', $data)
            && array_key_exists('away_goals', $data)) {
            $data['winner'] = MatchWinner::fromScores($data['home_goals'], $data['away_goals'])?->value;
        }

        $fixture->update($data);

        // Settling predictions when an admin marks a fixture finished directly.
        if ($fixture->wasChanged('status_group') && $fixture->status_group === FixtureStatusGroup::Finished) {
            SettleFixturePredictionsJob::dispatch($fixture->id);
        }

        return $this->ok(new FixtureAdminResource($this->loaded($fixture)), __('Fixture updated.'));
    }

    public function destroy(Fixture $fixture): JsonResponse
    {
        $fixture->delete();

        return $this->noContentMessage(__('Fixture deleted.'));
    }

    public function toggleLock(Fixture $fixture): JsonResponse
    {
        $fixture->update(['is_locked' => ! $fixture->is_locked]);

        return $this->ok(['is_locked' => $fixture->is_locked], __('Fixture updated.'));
    }

    protected function loaded(Fixture $fixture): Fixture
    {
        return $fixture->load(['league', 'homeTeam', 'awayTeam']);
    }
}
