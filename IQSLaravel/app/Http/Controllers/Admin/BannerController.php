<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Concerns\HandlesImageUploads;
use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\StoreBannerRequest;
use App\Http\Requests\Admin\UpdateBannerRequest;
use App\Http\Resources\Admin\BannerAdminResource;
use App\Models\Banner;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BannerController extends Controller
{
    use HandlesImageUploads;

    public function index(Request $request): JsonResponse
    {
        $banners = Banner::query()
            ->when($request->filled('placement'), fn ($q) => $q->where('placement', $request->string('placement')))
            ->when($request->filled('is_active'), fn ($q) => $q->where('is_active', $request->boolean('is_active')))
            ->orderBy('placement')
            ->orderBy('position')
            ->paginate(min((int) $request->integer('per_page', 20), 50))
            ->appends($request->query());

        return $this->ok(BannerAdminResource::collection($banners));
    }

    public function store(StoreBannerRequest $request): JsonResponse
    {
        $banner = Banner::create($request->validated());

        return $this->created(new BannerAdminResource($banner), __('Banner created.'));
    }

    public function upload(Request $request): JsonResponse
    {
        return $this->uploadImage($request, 'banners');
    }

    public function show(Banner $banner): JsonResponse
    {
        return $this->ok(new BannerAdminResource($banner));
    }

    public function update(UpdateBannerRequest $request, Banner $banner): JsonResponse
    {
        $banner->update($request->validated());

        return $this->ok(new BannerAdminResource($banner), __('Banner updated.'));
    }

    public function destroy(Banner $banner): JsonResponse
    {
        $banner->delete();

        return $this->noContentMessage(__('Banner deleted.'));
    }
}
