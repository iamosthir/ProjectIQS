<?php

namespace App\Http\Controllers\Admin\Matches;

use App\Http\Controllers\Controller;
use App\Http\Resources\Admin\BroadcastAdminResource;
use App\Models\Fixture;
use App\Models\FixtureBroadcast;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BroadcastController extends Controller
{
    public function index(Fixture $fixture): JsonResponse
    {
        return $this->ok(BroadcastAdminResource::collection(
            $fixture->broadcasts()->orderBy('display_order')->get()
        ));
    }

    public function store(Request $request, Fixture $fixture): JsonResponse
    {
        $broadcast = $fixture->broadcasts()->create($this->validated($request));

        return $this->created(new BroadcastAdminResource($broadcast), __('Channel added.'));
    }

    public function update(Request $request, Fixture $fixture, FixtureBroadcast $broadcast): JsonResponse
    {
        $this->ensureBelongs($fixture, $broadcast);
        $broadcast->update($this->validated($request));

        return $this->ok(new BroadcastAdminResource($broadcast), __('Channel updated.'));
    }

    public function destroy(Fixture $fixture, FixtureBroadcast $broadcast): JsonResponse
    {
        $this->ensureBelongs($fixture, $broadcast);
        $broadcast->delete();

        return $this->noContentMessage(__('Channel removed.'));
    }

    /**
     * @return array<string, mixed>
     */
    protected function validated(Request $request): array
    {
        return $request->validate([
            'channel_name' => ['required', 'string', 'max:255'],
            'channel_logo_path' => ['nullable', 'string', 'max:2048'],
            'stream_url' => ['nullable', 'string', 'max:2048'],
            'commentator_name' => ['nullable', 'string', 'max:255'],
            'display_order' => ['sometimes', 'integer'],
        ]);
    }

    protected function ensureBelongs(Fixture $fixture, FixtureBroadcast $broadcast): void
    {
        abort_unless($broadcast->fixture_id === $fixture->id, 404);
    }
}
