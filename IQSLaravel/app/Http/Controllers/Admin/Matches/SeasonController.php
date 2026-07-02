<?php

namespace App\Http\Controllers\Admin\Matches;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\Matches\SeasonRequest;
use App\Http\Resources\Admin\SeasonAdminResource;
use App\Models\Season;
use App\Support\Enums\Source;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SeasonController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $seasons = Season::query()
            ->when($request->filled('league_id'), fn ($q) => $q->where('league_id', $request->integer('league_id')))
            ->orderByDesc('year')
            ->get();

        return $this->ok(SeasonAdminResource::collection($seasons));
    }

    public function store(SeasonRequest $request): JsonResponse
    {
        $season = Season::create(array_merge($request->validated(), ['source' => Source::Manual]));
        $this->ensureSingleCurrent($season);

        return $this->created(new SeasonAdminResource($season), __('Season created.'));
    }

    public function update(SeasonRequest $request, Season $season): JsonResponse
    {
        $season->update($request->validated());
        $this->ensureSingleCurrent($season);

        return $this->ok(new SeasonAdminResource($season), __('Season updated.'));
    }

    public function destroy(Season $season): JsonResponse
    {
        $season->delete();

        return $this->noContentMessage(__('Season deleted.'));
    }

    /**
     * Only one current season per league.
     */
    protected function ensureSingleCurrent(Season $season): void
    {
        if ($season->is_current) {
            Season::query()
                ->where('league_id', $season->league_id)
                ->whereKeyNot($season->id)
                ->update(['is_current' => false]);
        }
    }
}
