<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\FanGroupChantResource;
use App\Http\Resources\FanGroupDetailResource;
use App\Http\Resources\FanGroupMediaResource;
use App\Http\Resources\FanGroupResource;
use App\Models\FanGroup;
use App\Models\Setting;
use App\Support\Enums\VerificationMethod;
use App\Support\Enums\VerificationStatus;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class FanGroupController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $groups = FanGroup::query()
            ->where('is_active', true)
            ->when($request->filled('club'), fn ($q) => $q->where('club_id', $request->integer('club')))
            ->when($request->filled('governorate'), fn ($q) => $q->where('governorate', $request->string('governorate')))
            ->when($request->filled('q'), fn ($q) => $q->where(fn ($w) => $w
                ->where('name_ar', 'like', '%'.$request->string('q').'%')
                ->orWhere('name_en', 'like', '%'.$request->string('q').'%')))
            ->orderByDesc('is_official')
            ->orderBy('display_order')
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok(FanGroupResource::collection($groups));
    }

    public function show(FanGroup $fanGroup): JsonResponse
    {
        $fanGroup->loadCount([
            'media as photos_count' => fn ($q) => $q->where('type', 'image'),
            'media as videos_count' => fn ($q) => $q->where('type', 'video'),
            'chants as chants_count',
        ])->load('documents');

        return $this->ok(new FanGroupDetailResource($fanGroup));
    }

    public function media(Request $request, FanGroup $fanGroup): JsonResponse
    {
        $media = $fanGroup->media()
            ->when($request->filled('type'), fn ($q) => $q->where('type', $request->string('type')))
            ->orderBy('display_order')
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok(FanGroupMediaResource::collection($media));
    }

    public function chants(FanGroup $fanGroup): JsonResponse
    {
        return $this->ok(FanGroupChantResource::collection($fanGroup->chants));
    }

    public function verifyRequest(Request $request, FanGroup $fanGroup): JsonResponse
    {
        if (! Setting::get('fan_groups', 'verification_enabled', false)) {
            return $this->fail(__('Fan group verification is not available yet.'), null, 403);
        }

        $data = $request->validate([
            'method' => ['required', Rule::enum(VerificationMethod::class)],
            'note' => ['nullable', 'string', 'max:1000'],
        ]);

        $verification = $fanGroup->verifications()->create([
            'user_id' => $request->user()->id,
            'method' => $data['method'],
            'note' => $data['note'] ?? null,
            'status' => VerificationStatus::Pending,
        ]);

        return $this->created([
            'id' => $verification->id,
            'status' => $verification->status->value,
        ], __('Verification request submitted.'));
    }
}
