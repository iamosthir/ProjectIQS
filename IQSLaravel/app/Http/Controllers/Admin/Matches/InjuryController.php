<?php

namespace App\Http\Controllers\Admin\Matches;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\Matches\InjuryRequest;
use App\Models\Injury;
use App\Support\Enums\Source;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class InjuryController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $injuries = Injury::query()
            ->with(['player', 'team', 'league', 'season', 'fixture'])
            ->when($request->filled('player_id'), fn ($q) => $q->where('player_id', $request->integer('player_id')))
            ->when($request->filled('team_id'), fn ($q) => $q->where('team_id', $request->integer('team_id')))
            ->when($request->filled('fixture_id'), fn ($q) => $q->where('fixture_id', $request->integer('fixture_id')))
            ->orderByDesc('date')
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok($injuries);
    }

    public function store(InjuryRequest $request): JsonResponse
    {
        $injury = Injury::create(array_merge($request->validated(), ['source' => Source::Manual]));

        return $this->created($injury->load(['player', 'team']), __('Injury created.'));
    }

    public function show(Injury $injury): JsonResponse
    {
        return $this->ok($injury->load(['player', 'team', 'league', 'season', 'fixture']));
    }

    public function update(InjuryRequest $request, Injury $injury): JsonResponse
    {
        $injury->update($request->validated());

        return $this->ok($injury->load(['player', 'team']), __('Injury updated.'));
    }

    public function destroy(Injury $injury): JsonResponse
    {
        $injury->delete();

        return $this->noContentMessage(__('Injury deleted.'));
    }
}
