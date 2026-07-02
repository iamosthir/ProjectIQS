<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\PageResource;
use App\Models\Page;
use Illuminate\Http\JsonResponse;

class PageController extends Controller
{
    /**
     * Public static page (privacy/terms/about) — store review needs these
     * reachable without auth (§8.4).
     */
    public function show(string $slug): JsonResponse
    {
        $page = Page::query()->where('slug', $slug)->where('is_active', true)->firstOrFail();

        return $this->ok(new PageResource($page));
    }
}
