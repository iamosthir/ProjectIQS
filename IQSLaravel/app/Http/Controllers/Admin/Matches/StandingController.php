<?php

namespace App\Http\Controllers\Admin\Matches;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\Matches\StandingRequest;
use App\Http\Resources\Admin\StandingAdminResource;
use App\Models\Standing;
use App\Support\Enums\Source;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StandingController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $standings = Standing::query()
            ->when($request->filled('league_id'), fn ($q) => $q->where('league_id', $request->integer('league_id')))
            ->when($request->filled('season_id'), fn ($q) => $q->where('season_id', $request->integer('season_id')))
            ->with('team')
            ->orderBy('group_label')
            ->orderBy('rank')
            ->get();

        return $this->ok(StandingAdminResource::collection($standings));
    }

    public function store(StandingRequest $request): JsonResponse
    {
        $standing = Standing::create(array_merge($request->validated(), ['source' => Source::Manual]));

        return $this->created(new StandingAdminResource($standing->load('team')), __('Standing row created.'));
    }

    public function update(StandingRequest $request, Standing $standing): JsonResponse
    {
        $standing->update($request->validated());

        return $this->ok(new StandingAdminResource($standing->load('team')), __('Standing row updated.'));
    }

    public function destroy(Standing $standing): JsonResponse
    {
        $standing->delete();

        return $this->noContentMessage(__('Standing row deleted.'));
    }
}
