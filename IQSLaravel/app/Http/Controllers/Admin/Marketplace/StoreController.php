<?php

namespace App\Http\Controllers\Admin\Marketplace;

use App\Http\Controllers\Controller;
use App\Http\Resources\Admin\StoreAdminResource;
use App\Models\Store;
use App\Support\Enums\StoreStatus;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Spatie\QueryBuilder\AllowedFilter;
use Spatie\QueryBuilder\QueryBuilder;

class StoreController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $stores = QueryBuilder::for(Store::class)
            ->allowedFilters([
                AllowedFilter::exact('status'),
                AllowedFilter::exact('is_verified'),
                AllowedFilter::callback('search', fn ($q, $v) => $q->where(fn ($w) => $w->where('name_en', 'like', "%{$v}%")->orWhere('name_ar', 'like', "%{$v}%"))),
            ])
            ->allowedSorts(['created_at', 'name_en'])
            ->defaultSort('-created_at')
            ->with('user')
            ->withCount('listings')
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok(StoreAdminResource::collection($stores));
    }

    public function show(Store $store): JsonResponse
    {
        return $this->ok(new StoreAdminResource($store->load('user')->loadCount('listings')));
    }

    public function verify(Store $store): JsonResponse
    {
        $store->update([
            'is_verified' => true,
            'verified_at' => now(),
            'status' => StoreStatus::Active,
        ]);

        return $this->ok(new StoreAdminResource($store->load('user')), __('Store verified.'));
    }

    public function suspend(Store $store): JsonResponse
    {
        $store->update(['status' => StoreStatus::Suspended]);

        return $this->ok(new StoreAdminResource($store->load('user')), __('Store suspended.'));
    }

    public function activate(Store $store): JsonResponse
    {
        $store->update(['status' => StoreStatus::Active]);

        return $this->ok(new StoreAdminResource($store->load('user')), __('Store activated.'));
    }
}
