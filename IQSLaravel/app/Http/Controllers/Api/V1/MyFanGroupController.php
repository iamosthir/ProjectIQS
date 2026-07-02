<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\FanGroupChantResource;
use App\Http\Resources\FanGroupDetailResource;
use App\Http\Resources\FanGroupMediaResource;
use App\Models\FanGroup;
use App\Models\FanGroupChant;
use App\Models\FanGroupDocument;
use App\Models\FanGroupMedia;
use App\Services\FanGroups\FanGroupArchiveService;
use App\Support\Enums\FanGroupMediaType;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/**
 * Group-admin management of the fan group they manage (§5.2). Archive limits
 * (100/30/20) are enforced by FanGroupArchiveService.
 */
class MyFanGroupController extends Controller
{
    public function __construct(private readonly FanGroupArchiveService $archive) {}

    public function show(Request $request): JsonResponse
    {
        $group = $this->group($request)->loadCount([
            'media as photos_count' => fn ($q) => $q->where('type', 'image'),
            'media as videos_count' => fn ($q) => $q->where('type', 'video'),
            'chants as chants_count',
        ])->load('documents');

        return $this->ok(new FanGroupDetailResource($group));
    }

    public function update(Request $request): JsonResponse
    {
        $group = $this->group($request);
        $group->update($request->validate($this->groupRules()));

        return $this->ok(new FanGroupDetailResource($group));
    }

    public function storeMedia(Request $request): JsonResponse
    {
        $media = $this->archive->addMedia($this->group($request), $request->validate([
            'type' => ['required', Rule::enum(FanGroupMediaType::class)],
            'path' => ['required', 'string', 'max:2048'],
            'thumbnail_path' => ['nullable', 'string', 'max:2048'],
            'title' => ['nullable', 'string', 'max:255'],
        ]));

        return $this->created(new FanGroupMediaResource($media), __('Media added.'));
    }

    public function destroyMedia(Request $request, FanGroupMedia $media): JsonResponse
    {
        abort_unless($media->fan_group_id === $this->group($request)->id, 403);
        $media->delete();

        return $this->noContentMessage(__('Media removed.'));
    }

    public function storeChant(Request $request): JsonResponse
    {
        $chant = $this->archive->addChant($this->group($request), $request->validate([
            'title_ar' => ['nullable', 'string', 'max:255'],
            'title_en' => ['nullable', 'string', 'max:255'],
            'video_path' => ['required', 'string', 'max:2048'],
            'thumbnail_path' => ['nullable', 'string', 'max:2048'],
            'lyrics' => ['nullable', 'string'],
        ]));

        return $this->created(new FanGroupChantResource($chant), __('Chant added.'));
    }

    public function destroyChant(Request $request, FanGroupChant $chant): JsonResponse
    {
        abort_unless($chant->fan_group_id === $this->group($request)->id, 403);
        $chant->delete();

        return $this->noContentMessage(__('Chant removed.'));
    }

    public function storeDocument(Request $request): JsonResponse
    {
        $document = $this->archive->addDocument($this->group($request), $request->validate([
            'title_ar' => ['nullable', 'string', 'max:255'],
            'title_en' => ['nullable', 'string', 'max:255'],
            'path' => ['required', 'string', 'max:2048'],
            'mime_type' => ['nullable', 'string', 'max:100'],
        ]));

        return $this->created($document, __('Document added.'));
    }

    public function destroyDocument(Request $request, FanGroupDocument $document): JsonResponse
    {
        abort_unless($document->fan_group_id === $this->group($request)->id, 403);
        $document->delete();

        return $this->noContentMessage(__('Document removed.'));
    }

    protected function group(Request $request): FanGroup
    {
        $group = $request->user()->managedFanGroup;

        abort_if($group === null, 403, __('You do not manage a fan group.'));

        return $group;
    }

    /**
     * @return array<string, mixed>
     */
    protected function groupRules(): array
    {
        return [
            'name_ar' => ['sometimes', 'required', 'string', 'max:255'],
            'name_en' => ['sometimes', 'required', 'string', 'max:255'],
            'founded_year' => ['sometimes', 'nullable', 'integer'],
            'group_logo_path' => ['sometimes', 'nullable', 'string', 'max:2048'],
            'club_logo_path' => ['sometimes', 'nullable', 'string', 'max:2048'],
            'cover_path' => ['sometimes', 'nullable', 'string', 'max:2048'],
            'description_ar' => ['sometimes', 'nullable', 'string'],
            'description_en' => ['sometimes', 'nullable', 'string'],
            'governorate' => ['sometimes', 'nullable', 'string', 'max:255'],
            'city' => ['sometimes', 'nullable', 'string', 'max:255'],
            'phone' => ['sometimes', 'nullable', 'string', 'max:30'],
            'facebook' => ['sometimes', 'nullable', 'string', 'max:255'],
            'instagram' => ['sometimes', 'nullable', 'string', 'max:255'],
            'twitter' => ['sometimes', 'nullable', 'string', 'max:255'],
        ];
    }
}
