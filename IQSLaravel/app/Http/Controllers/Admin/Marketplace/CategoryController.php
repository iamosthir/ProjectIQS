<?php

namespace App\Http\Controllers\Admin\Marketplace;

use App\Http\Controllers\Concerns\HandlesImageUploads;
use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\Marketplace\CategoryRequest;
use App\Http\Resources\Admin\CategoryAdminResource;
use App\Models\MarketplaceCategory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CategoryController extends Controller
{
    use HandlesImageUploads;

    public function upload(Request $request): JsonResponse
    {
        return $this->uploadImage($request, 'categories');
    }

    public function index(): JsonResponse
    {
        $categories = MarketplaceCategory::query()
            ->withCount('listings')
            ->orderBy('display_order')
            ->get();

        return $this->ok(CategoryAdminResource::collection($categories));
    }

    public function store(CategoryRequest $request): JsonResponse
    {
        $category = MarketplaceCategory::create($request->validated());

        return $this->created(new CategoryAdminResource($category), __('Category created.'));
    }

    public function show(MarketplaceCategory $category): JsonResponse
    {
        return $this->ok(new CategoryAdminResource($category->loadCount('listings')));
    }

    public function update(CategoryRequest $request, MarketplaceCategory $category): JsonResponse
    {
        $category->update($request->validated());

        return $this->ok(new CategoryAdminResource($category), __('Category updated.'));
    }

    public function destroy(MarketplaceCategory $category): JsonResponse
    {
        if ($category->listings()->exists()) {
            return $this->fail(__('This category has listings and cannot be deleted.'), null, 422);
        }

        $category->delete();

        return $this->noContentMessage(__('Category deleted.'));
    }
}
