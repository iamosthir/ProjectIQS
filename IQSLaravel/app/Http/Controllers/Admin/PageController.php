<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\StorePageRequest;
use App\Http\Requests\Admin\UpdatePageRequest;
use App\Http\Resources\Admin\PageAdminResource;
use App\Models\Page;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PageController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $pages = Page::query()
            ->orderBy('slug')
            ->paginate(min((int) $request->integer('per_page', 20), 50))
            ->appends($request->query());

        return $this->ok(PageAdminResource::collection($pages));
    }

    public function store(StorePageRequest $request): JsonResponse
    {
        $page = Page::create($request->validated());

        return $this->created(new PageAdminResource($page), __('Page created.'));
    }

    public function show(Page $page): JsonResponse
    {
        return $this->ok(new PageAdminResource($page));
    }

    public function update(UpdatePageRequest $request, Page $page): JsonResponse
    {
        $page->update($request->validated());

        return $this->ok(new PageAdminResource($page), __('Page updated.'));
    }

    public function destroy(Page $page): JsonResponse
    {
        $page->delete();

        return $this->noContentMessage(__('Page deleted.'));
    }
}
