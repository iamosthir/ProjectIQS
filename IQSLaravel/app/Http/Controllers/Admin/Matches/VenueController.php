<?php

namespace App\Http\Controllers\Admin\Matches;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\Matches\VenueRequest;
use App\Http\Resources\Admin\VenueAdminResource;
use App\Models\Venue;
use App\Support\Enums\Source;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Spatie\QueryBuilder\AllowedFilter;
use Spatie\QueryBuilder\QueryBuilder;

class VenueController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $venues = QueryBuilder::for(Venue::class)
            ->allowedFilters([
                AllowedFilter::exact('source'),
                AllowedFilter::callback('search', fn ($q, $v) => $q->where(fn ($w) => $w->where('name_en', 'like', "%{$v}%")->orWhere('name_ar', 'like', "%{$v}%")->orWhere('city', 'like', "%{$v}%"))),
            ])
            ->allowedSorts(['name_en', 'city', 'capacity', 'created_at'])
            ->defaultSort('name_en')
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok(VenueAdminResource::collection($venues));
    }

    public function store(VenueRequest $request): JsonResponse
    {
        $venue = Venue::create(array_merge($request->validated(), ['source' => Source::Manual]));

        return $this->created(new VenueAdminResource($venue), __('Venue created.'));
    }

    public function show(Venue $venue): JsonResponse
    {
        return $this->ok(new VenueAdminResource($venue));
    }

    public function update(VenueRequest $request, Venue $venue): JsonResponse
    {
        $venue->update($request->validated());

        return $this->ok(new VenueAdminResource($venue), __('Venue updated.'));
    }

    public function destroy(Venue $venue): JsonResponse
    {
        $venue->delete();

        return $this->noContentMessage(__('Venue deleted.'));
    }
}
