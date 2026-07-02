<?php

namespace App\Http\Controllers\Admin\Matches;

use App\Http\Controllers\Concerns\HandlesImageUploads;
use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\Matches\LeagueRequest;
use App\Http\Resources\Admin\LeagueAdminResource;
use App\Models\League;
use App\Support\Enums\Source;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Spatie\QueryBuilder\AllowedFilter;
use Spatie\QueryBuilder\QueryBuilder;

class LeagueController extends Controller
{
    use HandlesImageUploads;

    public function upload(Request $request): JsonResponse
    {
        return $this->uploadImage($request, 'leagues');
    }

    public function index(Request $request): JsonResponse
    {
        $leagues = QueryBuilder::for(League::class)
            ->allowedFilters([
                AllowedFilter::exact('is_iraqi'),
                AllowedFilter::exact('source'),
                AllowedFilter::exact('category'),
                AllowedFilter::callback('search', fn ($q, $v) => $q->where(fn ($w) => $w->where('name_en', 'like', "%{$v}%")->orWhere('name_ar', 'like', "%{$v}%"))),
            ])
            ->allowedSorts(['tier', 'display_order', 'name_en', 'created_at'])
            ->defaultSort('tier')
            ->withCount('seasons')
            ->with('currentSeason')
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok(LeagueAdminResource::collection($leagues));
    }

    public function store(LeagueRequest $request): JsonResponse
    {
        $league = League::create(array_merge($request->validated(), ['source' => Source::Manual]));

        return $this->created(new LeagueAdminResource($league), __('League created.'));
    }

    public function show(League $league): JsonResponse
    {
        return $this->ok(new LeagueAdminResource($league->load('currentSeason')->loadCount('seasons')));
    }

    public function update(LeagueRequest $request, League $league): JsonResponse
    {
        $league->update($request->validated());

        return $this->ok(new LeagueAdminResource($league), __('League updated.'));
    }

    public function destroy(League $league): JsonResponse
    {
        $league->delete();

        return $this->noContentMessage(__('League deleted.'));
    }

    /**
     * Pin/unpin a synced league against future syncs.
     */
    public function toggleLock(League $league): JsonResponse
    {
        $league->update(['is_locked' => ! $league->is_locked]);

        return $this->ok(['is_locked' => $league->is_locked], __('League updated.'));
    }
}
