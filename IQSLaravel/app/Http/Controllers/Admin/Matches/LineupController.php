<?php

namespace App\Http\Controllers\Admin\Matches;

use App\Http\Controllers\Concerns\HandlesImageUploads;
use App\Http\Controllers\Controller;
use App\Http\Resources\Admin\LineupAdminResource;
use App\Models\Fixture;
use App\Models\FixtureLineup;
use App\Support\Enums\Source;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LineupController extends Controller
{
    use HandlesImageUploads;

    /**
     * Upload a coach/player photo for the lineup builder; returns the stored
     * path which the form then submits as `coach_photo` / `players.*.photo_path`.
     */
    public function uploadPhoto(Request $request): JsonResponse
    {
        return $this->uploadImage($request, 'lineups');
    }

    public function index(Fixture $fixture): JsonResponse
    {
        return $this->ok(LineupAdminResource::collection($fixture->lineups()->with('players')->get()));
    }

    /**
     * Upsert a team's lineup (formation, coach, 11 + bench) — the pitch builder.
     */
    public function store(Request $request, Fixture $fixture): JsonResponse
    {
        $data = $request->validate([
            'team_id' => ['required', 'integer', 'exists:teams,id'],
            'formation' => ['nullable', 'string', 'max:20'],
            'coach_id' => ['nullable', 'integer', 'exists:coaches,id'],
            'coach_name' => ['nullable', 'string', 'max:255'],
            'coach_photo' => ['nullable', 'string', 'max:2048'],
            'players' => ['sometimes', 'array'],
            'players.*.player_id' => ['nullable', 'integer', 'exists:players,id'],
            'players.*.player_name' => ['required', 'string', 'max:255'],
            'players.*.photo_path' => ['nullable', 'string', 'max:2048'],
            'players.*.number' => ['nullable', 'integer', 'min:0', 'max:99'],
            'players.*.position' => ['nullable', 'string', 'max:10'],
            'players.*.grid' => ['nullable', 'string', 'max:10'],
            'players.*.is_starter' => ['sometimes', 'boolean'],
        ]);

        $lineup = $fixture->lineups()->updateOrCreate(
            ['team_id' => $data['team_id']],
            [
                'source' => Source::Manual,
                'formation' => $data['formation'] ?? null,
                'coach_id' => $data['coach_id'] ?? null,
                'coach_name' => $data['coach_name'] ?? null,
                'coach_photo' => $data['coach_photo'] ?? null,
            ],
        );

        $lineup->players()->delete();

        foreach ($data['players'] ?? [] as $player) {
            $lineup->players()->create([
                'player_id' => $player['player_id'] ?? null,
                'player_name' => $player['player_name'],
                'photo_path' => $player['photo_path'] ?? null,
                'number' => $player['number'] ?? null,
                'position' => $player['position'] ?? null,
                'grid' => $player['grid'] ?? null,
                'is_starter' => $player['is_starter'] ?? true,
            ]);
        }

        $fixture->update(['has_lineups' => true]);

        return $this->ok(new LineupAdminResource($lineup->load('players')), __('Lineup saved.'));
    }

    public function destroy(Fixture $fixture, FixtureLineup $lineup): JsonResponse
    {
        abort_unless($lineup->fixture_id === $fixture->id, 404);

        $lineup->players()->delete();
        $lineup->delete();

        if (! $fixture->lineups()->exists()) {
            $fixture->update(['has_lineups' => false]);
        }

        return $this->noContentMessage(__('Lineup removed.'));
    }
}
