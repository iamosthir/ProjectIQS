<?php

namespace App\Http\Controllers\Admin\Matches;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\Matches\CoachCareerRequest;
use App\Http\Requests\Admin\Matches\CoachRequest;
use App\Models\Coach;
use App\Models\CoachCareer;
use App\Support\Enums\Source;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CoachController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $coaches = Coach::query()
            ->with('team')
            ->when($request->filled('team_id'), fn ($q) => $q->where('team_id', $request->integer('team_id')))
            ->when($request->filled('search'), function ($q) use ($request) {
                $search = $request->string('search')->toString();
                $q->where(fn ($w) => $w
                    ->where('name_ar', 'like', "%{$search}%")
                    ->orWhere('name_en', 'like', "%{$search}%"));
            })
            ->orderBy('name_en')
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok($coaches);
    }

    public function store(CoachRequest $request): JsonResponse
    {
        $coach = Coach::create(array_merge($request->validated(), ['source' => Source::Manual]));

        return $this->created($coach, __('Coach created.'));
    }

    public function show(Coach $coach): JsonResponse
    {
        return $this->ok($coach->load(['team', 'careers.team']));
    }

    public function update(CoachRequest $request, Coach $coach): JsonResponse
    {
        $coach->update($request->validated());

        return $this->ok($coach, __('Coach updated.'));
    }

    public function destroy(Coach $coach): JsonResponse
    {
        $coach->delete();

        return $this->noContentMessage(__('Coach deleted.'));
    }

    /*
    |----------------------------------------------------------------------
    | Career entries (nested)
    |----------------------------------------------------------------------
    */

    public function careers(Coach $coach): JsonResponse
    {
        return $this->ok($coach->careers()->with('team')->get());
    }

    public function storeCareer(CoachCareerRequest $request, Coach $coach): JsonResponse
    {
        $career = $coach->careers()->create($request->validated());

        return $this->created($career->load('team'), __('Career entry added.'));
    }

    public function updateCareer(CoachCareerRequest $request, Coach $coach, CoachCareer $career): JsonResponse
    {
        abort_unless($career->coach_id === $coach->id, 404);

        $career->update($request->validated());

        return $this->ok($career->load('team'), __('Career entry updated.'));
    }

    public function destroyCareer(Coach $coach, CoachCareer $career): JsonResponse
    {
        abort_unless($career->coach_id === $coach->id, 404);

        $career->delete();

        return $this->noContentMessage(__('Career entry deleted.'));
    }
}
