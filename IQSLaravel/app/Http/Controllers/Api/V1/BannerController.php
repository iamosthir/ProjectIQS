<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\BannerResource;
use App\Models\Banner;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BannerController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $banners = Banner::query()
            ->live()
            ->when($request->filled('placement'), fn ($q) => $q->where('placement', $request->string('placement')))
            ->orderBy('placement')
            ->orderBy('position')
            ->get();

        return $this->ok(BannerResource::collection($banners));
    }
}
