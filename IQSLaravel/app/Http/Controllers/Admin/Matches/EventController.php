<?php

namespace App\Http\Controllers\Admin\Matches;

use App\Http\Controllers\Controller;
use App\Http\Resources\Admin\FixtureEventAdminResource;
use App\Jobs\SettleFixturePredictionsJob;
use App\Models\Fixture;
use App\Models\FixtureEvent;
use App\Models\Setting;
use App\Models\TopScorer;
use App\Services\Match\TopScorerService;
use App\Support\Enums\FixtureEventType;
use App\Support\Enums\FixtureStatusGroup;
use App\Support\Enums\Source;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class EventController extends Controller
{
    public function __construct(private readonly TopScorerService $scorers) {}

    public function index(Fixture $fixture): JsonResponse
    {
        return $this->ok(FixtureEventAdminResource::collection($fixture->events()->get()));
    }

    /**
     * Log a timeline event. Goals bump the top-scorers list; End-of-Match /
     * Cancelled / Postponed close the console by flipping status_group (and
     * End-of-Match settles predictions). (§2.1 / §2.6)
     */
    public function store(Request $request, Fixture $fixture): JsonResponse
    {
        $data = $request->validate([
            'type' => ['required', Rule::enum(FixtureEventType::class)],
            'detail' => ['required', 'string', 'max:255'],
            'elapsed' => ['sometimes', 'integer', 'min:0', 'max:130'],
            'extra' => ['nullable', 'integer', 'min:0', 'max:30'],
            'team_id' => ['nullable', 'integer', 'exists:teams,id'],
            'player_id' => ['nullable', 'integer', 'exists:players,id'],
            'player_name' => ['nullable', 'string', 'max:255'],
            'assist_player_id' => ['nullable', 'integer', 'exists:players,id'],
            'assist_name' => ['nullable', 'string', 'max:255'],
            'comments' => ['nullable', 'string', 'max:255'],
        ]);

        $type = FixtureEventType::from($data['type']);

        $event = $fixture->events()->create(array_merge($data, [
            'source' => Source::Manual,
            'elapsed' => $data['elapsed'] ?? 0,
            'display_order' => $fixture->events()->count(),
        ]));

        $fixture->update(['has_events' => true]);

        if ($type === FixtureEventType::Goal && Setting::get('match', 'auto_top_scorers', true)) {
            $this->bumpScorer($fixture, $event);
        }

        $this->applyStatusChange($fixture, $type);

        return $this->created(new FixtureEventAdminResource($event), __('Event logged.'));
    }

    /**
     * Edit a logged event (minute, player, detail, …). Unlike store this does
     * not re-bump top scorers or flip the match status, to avoid double counting
     * when correcting a typo.
     */
    public function update(Request $request, Fixture $fixture, FixtureEvent $event): JsonResponse
    {
        abort_unless($event->fixture_id === $fixture->id, 404);

        $data = $request->validate([
            'type' => ['sometimes', Rule::enum(FixtureEventType::class)],
            'detail' => ['sometimes', 'string', 'max:255'],
            'elapsed' => ['sometimes', 'integer', 'min:0', 'max:130'],
            'extra' => ['nullable', 'integer', 'min:0', 'max:30'],
            'team_id' => ['nullable', 'integer', 'exists:teams,id'],
            'player_id' => ['nullable', 'integer', 'exists:players,id'],
            'player_name' => ['nullable', 'string', 'max:255'],
            'assist_player_id' => ['nullable', 'integer', 'exists:players,id'],
            'assist_name' => ['nullable', 'string', 'max:255'],
            'comments' => ['nullable', 'string', 'max:255'],
        ]);

        $event->update($data);

        return $this->ok(new FixtureEventAdminResource($event->fresh()), __('Event updated.'));
    }

    public function destroy(Fixture $fixture, FixtureEvent $event): JsonResponse
    {
        abort_unless($event->fixture_id === $fixture->id, 404);
        $event->delete();

        return $this->noContentMessage(__('Event removed.'));
    }

    protected function applyStatusChange(Fixture $fixture, FixtureEventType $type): void
    {
        $status = $type->resultingStatus();

        if ($status === null) {
            return;
        }

        $fixture->update([
            'status_group' => $status->value,
            'status_short' => match ($status) {
                FixtureStatusGroup::Finished => 'FT',
                FixtureStatusGroup::Cancelled => 'CANC',
                FixtureStatusGroup::Postponed => 'PST',
                default => $fixture->status_short,
            },
        ]);

        if ($status === FixtureStatusGroup::Finished) {
            SettleFixturePredictionsJob::dispatch($fixture->id);
        }
    }

    protected function bumpScorer(Fixture $fixture, FixtureEvent $event): void
    {
        $scorer = TopScorer::firstOrNew([
            'league_id' => $fixture->league_id,
            'season_id' => $fixture->season_id,
            'player_id' => $event->player_id,
            ...($event->player_id === null ? ['player_name' => $event->player_name ?? 'Unknown'] : []),
        ]);

        $scorer->fill([
            'source' => Source::Manual,
            'player_name' => $event->player_name ?? $scorer->player_name ?? 'Unknown',
            'team_id' => $event->team_id,
        ]);
        $scorer->goals = ($scorer->goals ?? 0) + 1;
        $scorer->save();

        $this->scorers->recomputeRanks($fixture->league_id, $fixture->season_id);
    }
}
