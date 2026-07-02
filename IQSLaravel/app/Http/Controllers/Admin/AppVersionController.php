<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\StoreAppVersionRequest;
use App\Http\Requests\Admin\UpdateAppVersionRequest;
use App\Http\Resources\Admin\AppVersionResource;
use App\Models\AppVersion;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AppVersionController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $versions = AppVersion::query()
            ->when($request->filled('platform'), fn ($q) => $q->where('platform', $request->string('platform')))
            ->orderByDesc('build_number')
            ->paginate(min((int) $request->integer('per_page', 20), 50))
            ->appends($request->query());

        return $this->ok(AppVersionResource::collection($versions));
    }

    public function store(StoreAppVersionRequest $request): JsonResponse
    {
        $version = AppVersion::create($request->validated());

        return $this->created(new AppVersionResource($version), __('App version created.'));
    }

    public function show(AppVersion $appVersion): JsonResponse
    {
        return $this->ok(new AppVersionResource($appVersion));
    }

    public function update(UpdateAppVersionRequest $request, AppVersion $appVersion): JsonResponse
    {
        $appVersion->update($request->validated());

        return $this->ok(new AppVersionResource($appVersion), __('App version updated.'));
    }

    public function destroy(AppVersion $appVersion): JsonResponse
    {
        $appVersion->delete();

        return $this->noContentMessage(__('App version deleted.'));
    }
}
