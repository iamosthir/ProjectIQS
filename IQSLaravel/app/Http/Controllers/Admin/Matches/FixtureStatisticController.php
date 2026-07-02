<?php

namespace App\Http\Controllers\Admin\Matches;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\Matches\FixtureStatisticRequest;
use App\Http\Resources\Admin\FixtureStatisticAdminResource;
use App\Models\Fixture;
use App\Models\FixtureStatistic;
use App\Support\Enums\Source;
use Illuminate\Http\JsonResponse;

class FixtureStatisticController extends Controller
{
    public function index(Fixture $fixture): JsonResponse
    {
        return $this->ok(
            FixtureStatisticAdminResource::collection(
                $fixture->statistics()->orderBy('display_order')->get(),
            ),
        );
    }

    /**
     * Bulk-save the fixture's manual statistics: replaces all manual rows with
     * the submitted set (api_football rows are untouched, so a synced fixture's
     * provider stats and hand-entered stats coexist).
     */
    public function store(FixtureStatisticRequest $request, Fixture $fixture): JsonResponse
    {
        $rows = $request->validated()['statistics'];

        $fixture->statistics()->where('source', Source::Manual)->delete();

        $order = 0;
        foreach ($rows as $row) {
            $fixture->statistics()->create([
                'team_id' => $row['team_id'],
                'source' => Source::Manual,
                'type' => $row['type'],
                'value' => $row['value'] ?? null,
                'value_numeric' => $row['value_numeric'] ?? $this->toNumeric($row['value'] ?? null),
                'display_order' => $row['display_order'] ?? $order++,
            ]);
        }

        $fixture->update(['has_statistics' => $fixture->statistics()->exists()]);

        return $this->ok(
            FixtureStatisticAdminResource::collection($fixture->statistics()->orderBy('display_order')->get()),
            __('Statistics saved.'),
        );
    }

    public function destroy(Fixture $fixture, FixtureStatistic $statistic): JsonResponse
    {
        abort_unless($statistic->fixture_id === $fixture->id, 404);

        $statistic->delete();
        $fixture->update(['has_statistics' => $fixture->statistics()->exists()]);

        return $this->noContentMessage(__('Statistic removed.'));
    }

    /**
     * Best-effort parse of a display value ("62%", "7") to a sortable number.
     */
    protected function toNumeric(mixed $value): ?float
    {
        if ($value === null || $value === '') {
            return null;
        }

        $clean = str_replace('%', '', (string) $value);

        return is_numeric($clean) ? (float) $clean : null;
    }
}
