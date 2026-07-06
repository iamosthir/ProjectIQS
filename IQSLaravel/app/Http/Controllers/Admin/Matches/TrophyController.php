<?php

namespace App\Http\Controllers\Admin\Matches;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\Matches\TrophyRequest;
use App\Models\Trophy;
use App\Support\Enums\Source;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TrophyController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $trophies = Trophy::query()
            ->with(['player', 'coach'])
            ->when($request->filled('player_id'), fn ($q) => $q->where('player_id', $request->integer('player_id')))
            ->when($request->filled('coach_id'), fn ($q) => $q->where('coach_id', $request->integer('coach_id')))
            ->orderByDesc('season')
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok($trophies);
    }

    public function store(TrophyRequest $request): JsonResponse
    {
        $trophy = Trophy::create(array_merge($request->validated(), ['source' => Source::Manual]));

        return $this->created($trophy, __('Trophy created.'));
    }

    public function show(Trophy $trophy): JsonResponse
    {
        return $this->ok($trophy->load(['player', 'coach']));
    }

    public function update(TrophyRequest $request, Trophy $trophy): JsonResponse
    {
        $trophy->update($request->validated());

        return $this->ok($trophy, __('Trophy updated.'));
    }

    public function destroy(Trophy $trophy): JsonResponse
    {
        $trophy->delete();

        return $this->noContentMessage(__('Trophy deleted.'));
    }
}
