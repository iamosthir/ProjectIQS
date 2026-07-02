<?php

namespace App\Http\Controllers\Admin\Matches;

use App\Http\Controllers\Controller;
use App\Http\Resources\Admin\TopScorerAdminResource;
use App\Models\League;
use App\Models\TopScorer;
use App\Services\Match\TopScorerService;
use App\Support\Enums\Source;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TopScorerController extends Controller
{
    public function __construct(private readonly TopScorerService $scorers) {}

    public function index(Request $request, League $league): JsonResponse
    {
        $scorers = TopScorer::query()
            ->where('league_id', $league->id)
            ->when($request->filled('season_id'), fn ($q) => $q->where('season_id', $request->integer('season_id')))
            ->orderByRaw('rank IS NULL, rank')
            ->orderByDesc('goals')
            ->get();

        return $this->ok(TopScorerAdminResource::collection($scorers));
    }

    public function store(Request $request, League $league): JsonResponse
    {
        $data = $this->validated($request);
        $scorer = $league->topScorers()->create(array_merge($data, ['source' => Source::Manual]));

        $this->scorers->recomputeRanks($league->id, $data['season_id'] ?? null);

        return $this->created(new TopScorerAdminResource($scorer->fresh()), __('Scorer added.'));
    }

    public function update(Request $request, League $league, TopScorer $topScorer): JsonResponse
    {
        abort_unless($topScorer->league_id === $league->id, 404);

        $topScorer->update($this->validated($request));
        $this->scorers->recomputeRanks($league->id, $topScorer->season_id);

        return $this->ok(new TopScorerAdminResource($topScorer->fresh()), __('Scorer updated.'));
    }

    public function destroy(League $league, TopScorer $topScorer): JsonResponse
    {
        abort_unless($topScorer->league_id === $league->id, 404);

        $seasonId = $topScorer->season_id;
        $topScorer->delete();
        $this->scorers->recomputeRanks($league->id, $seasonId);

        return $this->noContentMessage(__('Scorer removed.'));
    }

    /**
     * @return array<string, mixed>
     */
    protected function validated(Request $request): array
    {
        return $request->validate([
            'player_name' => ['required', 'string', 'max:255'],
            'player_id' => ['nullable', 'integer', 'exists:players,id'],
            'player_photo_path' => ['nullable', 'string', 'max:2048'],
            'team_id' => ['nullable', 'integer', 'exists:teams,id'],
            'team_name' => ['nullable', 'string', 'max:255'],
            'season_id' => ['nullable', 'integer', 'exists:seasons,id'],
            'goals' => ['sometimes', 'integer', 'min:0'],
            'assists' => ['nullable', 'integer', 'min:0'],
            'penalties' => ['nullable', 'integer', 'min:0'],
        ]);
    }
}
