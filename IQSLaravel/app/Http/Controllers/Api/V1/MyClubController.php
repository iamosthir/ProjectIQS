<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ClubDetailResource;
use App\Models\Club;
use App\Models\ClubNews;
use App\Services\Clubs\ClubContentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Club-admin management of the club they manage (managed_by) — §4.2.
 */
class MyClubController extends Controller
{
    public function __construct(private readonly ClubContentService $content) {}

    public function show(Request $request): JsonResponse
    {
        $club = $this->club($request)->load(['boardMembers', 'staff', 'titles', 'captains', 'competitions']);

        return $this->ok(new ClubDetailResource($club));
    }

    public function update(Request $request): JsonResponse
    {
        $club = $this->club($request);
        $club->update($request->validate($this->clubRules()));

        return $this->ok(new ClubDetailResource($club));
    }

    public function storeChild(Request $request, string $type): JsonResponse
    {
        $club = $this->club($request);
        abort_unless(ClubContentService::isValidType($type), 404);

        $child = $this->content->create($club, $type, $request->validate(ClubContentService::rules($type, true)));

        return $this->created($child, __('Saved.'));
    }

    public function updateChild(Request $request, string $type, int $id): JsonResponse
    {
        $club = $this->club($request);
        abort_unless(ClubContentService::isValidType($type), 404);

        $child = $this->content->find($club, $type, $id);
        $child->update($request->validate(ClubContentService::rules($type, false)));

        return $this->ok($child, __('Updated.'));
    }

    public function destroyChild(Request $request, string $type, int $id): JsonResponse
    {
        $club = $this->club($request);
        abort_unless(ClubContentService::isValidType($type), 404);

        $this->content->find($club, $type, $id)->delete();

        return $this->noContentMessage(__('Removed.'));
    }

    public function storeNews(Request $request): JsonResponse
    {
        $club = $this->club($request);
        $news = $club->news()->create($request->validate($this->newsRules(true)));

        return $this->created($news, __('News created.'));
    }

    public function updateNews(Request $request, ClubNews $news): JsonResponse
    {
        $this->ensureNews($request, $news);
        $news->update($request->validate($this->newsRules(false)));

        return $this->ok($news, __('News updated.'));
    }

    public function destroyNews(Request $request, ClubNews $news): JsonResponse
    {
        $this->ensureNews($request, $news);
        $news->delete();

        return $this->noContentMessage(__('News deleted.'));
    }

    protected function club(Request $request): Club
    {
        $club = $request->user()->managedClub;

        abort_if($club === null, 403, __('You do not manage a club.'));

        return $club;
    }

    protected function ensureNews(Request $request, ClubNews $news): void
    {
        abort_unless($news->club_id === $this->club($request)->id, 403);
    }

    /**
     * @return array<string, mixed>
     */
    protected function clubRules(): array
    {
        return [
            'name_ar' => ['sometimes', 'required', 'string', 'max:255'],
            'name_en' => ['sometimes', 'required', 'string', 'max:255'],
            'logo_path' => ['sometimes', 'nullable', 'string', 'max:2048'],
            'cover_path' => ['sometimes', 'nullable', 'string', 'max:2048'],
            'founded_year' => ['sometimes', 'nullable', 'integer'],
            'description_ar' => ['sometimes', 'nullable', 'string'],
            'description_en' => ['sometimes', 'nullable', 'string'],
            'governorate' => ['sometimes', 'nullable', 'string', 'max:255'],
            'city' => ['sometimes', 'nullable', 'string', 'max:255'],
            'address' => ['sometimes', 'nullable', 'string', 'max:255'],
            'latitude' => ['sometimes', 'nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['sometimes', 'nullable', 'numeric', 'between:-180,180'],
            'phone' => ['sometimes', 'nullable', 'string', 'max:30'],
            'email' => ['sometimes', 'nullable', 'email', 'max:255'],
            'website' => ['sometimes', 'nullable', 'string', 'max:255'],
            'facebook' => ['sometimes', 'nullable', 'string', 'max:255'],
            'instagram' => ['sometimes', 'nullable', 'string', 'max:255'],
            'twitter' => ['sometimes', 'nullable', 'string', 'max:255'],
        ];
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
