<?php

namespace App\Http\Controllers\Admin\Matches;

use App\Http\Controllers\Concerns\HandlesImageUploads;
use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\Matches\FixtureNewsRequest;
use App\Http\Resources\Admin\FixtureNewsAdminResource;
use App\Models\Fixture;
use App\Models\FixtureNews;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FixtureNewsController extends Controller
{
    use HandlesImageUploads;

    /**
     * Admin list: ALL news for the fixture, including unpublished (unlike the
     * mobile endpoint which shows published only).
     */
    public function index(Fixture $fixture): JsonResponse
    {
        return $this->ok(FixtureNewsAdminResource::collection($fixture->news()->get()));
    }

    public function store(FixtureNewsRequest $request, Fixture $fixture): JsonResponse
    {
        $data = $request->validated();

        $news = $fixture->news()->create(array_merge($data, [
            'source' => 'manual',
            'is_published' => $data['is_published'] ?? true,
            'published_at' => $data['published_at'] ?? now(),
        ]));

        return $this->created(new FixtureNewsAdminResource($news), __('News created.'));
    }

    public function update(FixtureNewsRequest $request, Fixture $fixture, FixtureNews $news): JsonResponse
    {
        abort_unless($news->fixture_id === $fixture->id, 404);

        $news->update($request->validated());

        return $this->ok(new FixtureNewsAdminResource($news->fresh()), __('News updated.'));
    }

    public function destroy(Fixture $fixture, FixtureNews $news): JsonResponse
    {
        abort_unless($news->fixture_id === $fixture->id, 404);

        $news->delete();

        return $this->noContentMessage(__('News deleted.'));
    }

    public function upload(Request $request): JsonResponse
    {
        return $this->uploadImage($request, 'fixture_news');
    }
}
