<?php

namespace App\Http\Controllers\Admin\Clubs;

use App\Http\Controllers\Concerns\HandlesImageUploads;
use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\Clubs\ClubRequest;
use App\Http\Resources\Admin\ClubAdminResource;
use App\Models\Club;
use App\Models\ClubNews;
use App\Models\User;
use App\Services\Clubs\ClubContentService;
use App\Support\Enums\ClubStatus;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Spatie\QueryBuilder\AllowedFilter;
use Spatie\QueryBuilder\QueryBuilder;

class ClubController extends Controller
{
    use HandlesImageUploads;

    public function __construct(private readonly ClubContentService $content) {}

    public function upload(Request $request): JsonResponse
    {
        return $this->uploadImage($request, 'clubs');
    }

    public function index(Request $request): JsonResponse
    {
        $clubs = QueryBuilder::for(Club::class)
            ->allowedFilters([
                AllowedFilter::exact('status'),
                AllowedFilter::exact('is_verified'),
                AllowedFilter::exact('governorate'),
                AllowedFilter::callback('search', fn ($q, $v) => $q->where(fn ($w) => $w->where('name_en', 'like', "%{$v}%")->orWhere('name_ar', 'like', "%{$v}%"))),
            ])
            ->allowedSorts(['display_order', 'name_en', 'created_at'])
            ->defaultSort('display_order')
            ->with('manager')
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok(ClubAdminResource::collection($clubs));
    }

    public function store(ClubRequest $request): JsonResponse
    {
        $club = Club::create($request->validated());
        $this->syncManagerRole($club);

        return $this->created(new ClubAdminResource($club->load('manager')), __('Club created.'));
    }

    public function show(Club $club): JsonResponse
    {
        return $this->ok(new ClubAdminResource(
            $club->load(['manager', 'boardMembers', 'staff', 'titles', 'captains', 'competitions', 'news'])
        ));
    }

    public function update(ClubRequest $request, Club $club): JsonResponse
    {
        $club->update($request->validated());
        $this->syncManagerRole($club);

        return $this->ok(new ClubAdminResource($club->load('manager')), __('Club updated.'));
    }

    public function destroy(Club $club): JsonResponse
    {
        $club->delete();

        return $this->noContentMessage(__('Club deleted.'));
    }

    public function verify(Club $club): JsonResponse
    {
        $club->update(['is_verified' => true, 'verified_at' => now(), 'status' => ClubStatus::Active]);

        return $this->ok(new ClubAdminResource($club), __('Club verified.'));
    }

    // --- Nested content ---

    public function storeChild(Request $request, Club $club, string $type): JsonResponse
    {
        abort_unless(ClubContentService::isValidType($type), 404);
        $child = $this->content->create($club, $type, $request->validate(ClubContentService::rules($type, true)));

        return $this->created($child, __('Saved.'));
    }

    public function updateChild(Request $request, Club $club, string $type, int $id): JsonResponse
    {
        abort_unless(ClubContentService::isValidType($type), 404);
        $child = $this->content->find($club, $type, $id);
        $child->update($request->validate(ClubContentService::rules($type, false)));

        return $this->ok($child, __('Updated.'));
    }

    public function destroyChild(Club $club, string $type, int $id): JsonResponse
    {
        abort_unless(ClubContentService::isValidType($type), 404);
        $this->content->find($club, $type, $id)->delete();

        return $this->noContentMessage(__('Removed.'));
    }

    public function storeNews(Request $request, Club $club): JsonResponse
    {
        $news = $club->news()->create($request->validate($this->newsRules(true)));

        return $this->created($news, __('News created.'));
    }

    public function updateNews(Request $request, Club $club, ClubNews $news): JsonResponse
    {
        abort_unless($news->club_id === $club->id, 404);
        $news->update($request->validate($this->newsRules(false)));

        return $this->ok($news, __('News updated.'));
    }

    public function destroyNews(Club $club, ClubNews $news): JsonResponse
    {
        abort_unless($news->club_id === $club->id, 404);
        $news->delete();

        return $this->noContentMessage(__('News deleted.'));
    }

    protected function syncManagerRole(Club $club): void
    {
        if ($club->managed_by !== null) {
            User::find($club->managed_by)?->assignRole('club-admin');
        }
    }

    /**
     * @return array<string, mixed>
     */
    protected function newsRules(bool $create): array
    {
        $r = $create ? 'required' : 'sometimes';

        return [
            'title_ar' => [$r, 'string', 'max:255'],
            'title_en' => ['nullable', 'string', 'max:255'],
            'excerpt_ar' => ['nullable', 'string'],
            'excerpt_en' => ['nullable', 'string'],
            'content_ar' => [$r, 'string'],
            'content_en' => ['nullable', 'string'],
            'cover_path' => ['nullable', 'string', 'max:2048'],
            'author_name' => ['nullable', 'string', 'max:255'],
            'is_published' => ['sometimes', 'boolean'],
            'published_at' => ['sometimes', 'nullable', 'date'],
        ];
    }
}
