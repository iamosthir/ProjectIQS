<?php

namespace App\Http\Controllers\Admin\Matches;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\Matches\SidelinedRequest;
use App\Models\Sidelined;
use App\Support\Enums\Source;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SidelinedController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $sidelined = Sidelined::query()
            ->with(['player', 'coach'])
            ->when($request->filled('player_id'), fn ($q) => $q->where('player_id', $request->integer('player_id')))
            ->when($request->filled('coach_id'), fn ($q) => $q->where('coach_id', $request->integer('coach_id')))
            ->orderByDesc('start_date')
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok($sidelined);
    }

    public function store(SidelinedRequest $request): JsonResponse
    {
        $spell = Sidelined::create(array_merge($request->validated(), ['source' => Source::Manual]));

        return $this->created($spell, __('Sidelined entry created.'));
    }

    public function show(Sidelined $sidelined): JsonResponse
    {
        return $this->ok($sidelined->load(['player', 'coach']));
    }

    public function update(SidelinedRequest $request, Sidelined $sidelined): JsonResponse
    {
        $sidelined->update($request->validated());

        return $this->ok($sidelined, __('Sidelined entry updated.'));
    }

    public function destroy(Sidelined $sidelined): JsonResponse
    {
        $sidelined->delete();

        return $this->noContentMessage(__('Sidelined entry deleted.'));
    }
}
