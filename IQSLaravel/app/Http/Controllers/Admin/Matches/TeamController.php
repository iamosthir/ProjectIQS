<?php

namespace App\Http\Controllers\Admin\Matches;

use App\Http\Controllers\Concerns\HandlesImageUploads;
use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\Matches\TeamRequest;
use App\Http\Resources\Admin\TeamAdminResource;
use App\Models\Team;
use App\Support\Enums\Source;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Spatie\QueryBuilder\AllowedFilter;
use Spatie\QueryBuilder\QueryBuilder;

class TeamController extends Controller
{
    use HandlesImageUploads;

    public function upload(Request $request): JsonResponse
    {
        return $this->uploadImage($request, 'teams');
    }

    public function index(Request $request): JsonResponse
    {
        $teams = QueryBuilder::for(Team::class)
            ->allowedFilters([
                AllowedFilter::exact('source'),
                AllowedFilter::exact('is_national'),
                AllowedFilter::callback('search', fn ($q, $v) => $q->where(fn ($w) => $w->where('name_en', 'like', "%{$v}%")->orWhere('name_ar', 'like', "%{$v}%"))),
            ])
            ->allowedSorts(['name_en', 'created_at'])
            ->defaultSort('name_en')
            ->with('venue')
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok(TeamAdminResource::collection($teams));
    }

    public function store(TeamRequest $request): JsonResponse
    {
        $team = Team::create(array_merge($request->validated(), ['source' => Source::Manual]));

        return $this->created(new TeamAdminResource($team), __('Team created.'));
    }

    public function show(Team $team): JsonResponse
    {
        return $this->ok(new TeamAdminResource($team->load('venue')));
    }

    public function update(TeamRequest $request, Team $team): JsonResponse
    {
        $team->update($request->validated());

        return $this->ok(new TeamAdminResource($team->load('venue')), __('Team updated.'));
    }

    public function destroy(Team $team): JsonResponse
    {
        $team->delete();

        return $this->noContentMessage(__('Team deleted.'));
    }

    public function toggleLock(Team $team): JsonResponse
    {
        $team->update(['is_locked' => ! $team->is_locked]);

        return $this->ok(['is_locked' => $team->is_locked], __('Team updated.'));
    }
}
