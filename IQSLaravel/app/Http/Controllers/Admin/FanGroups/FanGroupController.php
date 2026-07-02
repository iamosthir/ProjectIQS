<?php

namespace App\Http\Controllers\Admin\FanGroups;

use App\Http\Controllers\Concerns\HandlesImageUploads;
use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\FanGroups\FanGroupRequest;
use App\Http\Resources\Admin\FanGroupAdminResource;
use App\Models\FanGroup;
use App\Models\FanGroupChant;
use App\Models\FanGroupDocument;
use App\Models\FanGroupMedia;
use App\Models\User;
use App\Services\FanGroups\FanGroupArchiveService;
use App\Support\Enums\FanGroupMediaType;
use App\Support\Enums\FanGroupStatus;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Spatie\QueryBuilder\AllowedFilter;
use Spatie\QueryBuilder\QueryBuilder;

class FanGroupController extends Controller
{
    use HandlesImageUploads;

    public function __construct(private readonly FanGroupArchiveService $archive) {}

    public function upload(Request $request): JsonResponse
    {
        return $this->uploadImage($request, 'fan-groups');
    }

    public function index(Request $request): JsonResponse
    {
        $groups = QueryBuilder::for(FanGroup::class)
            ->allowedFilters([
                AllowedFilter::exact('status'),
                AllowedFilter::exact('is_official'),
                AllowedFilter::exact('is_verified'),
                AllowedFilter::exact('club_id'),
                AllowedFilter::callback('search', fn ($q, $v) => $q->where(fn ($w) => $w->where('name_en', 'like', "%{$v}%")->orWhere('name_ar', 'like', "%{$v}%"))),
            ])
            ->allowedSorts(['display_order', 'name_en', 'created_at'])
            ->defaultSort('display_order')
            ->with('manager')
            ->withCount(['media', 'chants'])
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok(FanGroupAdminResource::collection($groups));
    }

    public function store(FanGroupRequest $request): JsonResponse
    {
        $group = FanGroup::create($request->validated());
        $this->syncManagerRole($group);

        return $this->created(new FanGroupAdminResource($group->load('manager')), __('Fan group created.'));
    }

    public function show(FanGroup $fanGroup): JsonResponse
    {
        return $this->ok(new FanGroupAdminResource(
            $fanGroup->load(['manager', 'media', 'chants', 'documents'])->loadCount(['media', 'chants'])
        ));
    }

    public function update(FanGroupRequest $request, FanGroup $fanGroup): JsonResponse
    {
        $fanGroup->update($request->validated());
        $this->syncManagerRole($fanGroup);

        return $this->ok(new FanGroupAdminResource($fanGroup->load('manager')), __('Fan group updated.'));
    }

    public function destroy(FanGroup $fanGroup): JsonResponse
    {
        $fanGroup->delete();

        return $this->noContentMessage(__('Fan group deleted.'));
    }

    public function verify(FanGroup $fanGroup): JsonResponse
    {
        $fanGroup->update([
            'is_verified' => true, 'is_official' => true, 'verified_at' => now(), 'status' => FanGroupStatus::Active,
        ]);

        return $this->ok(new FanGroupAdminResource($fanGroup), __('Fan group verified.'));
    }

    // --- Archives ---

    public function storeMedia(Request $request, FanGroup $fanGroup): JsonResponse
    {
        $media = $this->archive->addMedia($fanGroup, $request->validate([
            'type' => ['required', Rule::enum(FanGroupMediaType::class)],
            'path' => ['required', 'string', 'max:2048'],
            'thumbnail_path' => ['nullable', 'string', 'max:2048'],
            'title' => ['nullable', 'string', 'max:255'],
        ]));

        return $this->created($media, __('Media added.'));
    }

    public function destroyMedia(FanGroup $fanGroup, FanGroupMedia $media): JsonResponse
    {
        abort_unless($media->fan_group_id === $fanGroup->id, 404);
        $media->delete();

        return $this->noContentMessage(__('Media removed.'));
    }

    public function storeChant(Request $request, FanGroup $fanGroup): JsonResponse
    {
        $chant = $this->archive->addChant($fanGroup, $request->validate([
            'title_ar' => ['nullable', 'string', 'max:255'],
            'title_en' => ['nullable', 'string', 'max:255'],
            'video_path' => ['required', 'string', 'max:2048'],
            'thumbnail_path' => ['nullable', 'string', 'max:2048'],
            'lyrics' => ['nullable', 'string'],
        ]));

        return $this->created($chant, __('Chant added.'));
    }

    public function destroyChant(FanGroup $fanGroup, FanGroupChant $chant): JsonResponse
    {
        abort_unless($chant->fan_group_id === $fanGroup->id, 404);
        $chant->delete();

        return $this->noContentMessage(__('Chant removed.'));
    }

    public function storeDocument(Request $request, FanGroup $fanGroup): JsonResponse
    {
        $document = $this->archive->addDocument($fanGroup, $request->validate([
            'title_ar' => ['nullable', 'string', 'max:255'],
            'title_en' => ['nullable', 'string', 'max:255'],
            'path' => ['required', 'string', 'max:2048'],
            'mime_type' => ['nullable', 'string', 'max:100'],
        ]));

        return $this->created($document, __('Document added.'));
    }

    public function destroyDocument(FanGroup $fanGroup, FanGroupDocument $document): JsonResponse
    {
        abort_unless($document->fan_group_id === $fanGroup->id, 404);
        $document->delete();

        return $this->noContentMessage(__('Document removed.'));
    }

    protected function syncManagerRole(FanGroup $group): void
    {
        if ($group->managed_by !== null) {
            User::find($group->managed_by)?->assignRole('group-admin');
        }
    }
}
