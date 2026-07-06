<?php

namespace App\Http\Controllers\Api\V1\Football;

use App\Models\Fixture;
use App\Models\Standing;
use App\Models\Team;
use App\Support\Enums\FixtureStatusGroup;
use App\Support\Football\FootballShape;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;

class PredictionController extends FootballController
{
    /**
     * GET /football/predictions — mirrors API-Football `predictions`.
     * Required: fixture. The editorial forecast comes from
     * `fixture_forecasts`; the teams/h2h comparison blocks are computed
     * from our own fixtures and standings.
     */
    public function index(Request $request): JsonResponse
    {
        $request->validate(['fixture' => ['required', 'integer']]);

        $fixture = Fixture::query()
            ->with(['league.country', 'season', 'homeTeam', 'awayTeam', 'forecast.winnerTeam'])
            ->find($request->integer('fixture'));

        if ($fixture === null) {
            return $this->fail(__('Fixture not found.'), status: 404);
        }

        $forecast = $fixture->forecast;
        $percent = fn (?int $value): ?string => $value !== null ? $value.'%' : null;

        $item = [
            'predictions' => [
                'winner' => [
                    'id' => $forecast?->winner_team_id,
                    'name' => $forecast?->winnerTeam !== null
                        ? FootballShape::teamRef($forecast->winnerTeam)['name']
                        : null,
                    'comment' => $forecast?->winner_comment,
                ],
                'win_or_draw' => $forecast?->win_or_draw ?? false,
                'under_over' => $forecast?->under_over,
                'goals' => [
                    'home' => $forecast?->goals_home,
                    'away' => $forecast?->goals_away,
                ],
                'advice' => $forecast?->advice,
                'percent' => [
                    'home' => $percent($forecast?->percent_home),
                    'draw' => $percent($forecast?->percent_draw),
                    'away' => $percent($forecast?->percent_away),
                ],
            ],
            'league' => FootballShape::leagueBlock($fixture->league, $fixture->season),
            'teams' => [
                'home' => $this->teamBlock($fixture, $fixture->homeTeam),
                'away' => $this->teamBlock($fixture, $fixture->awayTeam),
            ],
            'comparison' => $forecast?->comparison,
            'h2h' => $this->headToHead($fixture)
                ->map(fn (Fixture $played): array => FootballShape::fixture($played))
                ->all(),
        ];

        return $this->ok([$item], meta: ['results' => 1]);
    }

    /**
     * Last-5 form + league record for one side, computed from played
     * fixtures and the standings table.
     *
     * @return array<string, mixed>
     */
    private function teamBlock(Fixture $fixture, ?Team $team): array
    {
        if ($team === null) {
            return ['id' => null, 'name' => null, 'logo' => null];
        }

        $lastFive = Fixture::query()
            ->where('status_group', FixtureStatusGroup::Finished)
            ->where('match_datetime', '<', $fixture->match_datetime ?? now())
            ->where(fn ($q) => $q->where('home_team_id', $team->id)->orWhere('away_team_id', $team->id))
            ->orderByDesc('match_datetime')
            ->limit(5)
            ->get();

        $results = $lastFive->map(function (Fixture $played) use ($team): array {
            $isHome = $played->home_team_id === $team->id;

            return [
                'for' => (int) ($isHome ? $played->home_goals : $played->away_goals),
                'against' => (int) ($isHome ? $played->away_goals : $played->home_goals),
            ];
        });

        $played = $results->count();
        $points = $results->sum(fn ($r) => $r['for'] > $r['against'] ? 3 : ($r['for'] === $r['against'] ? 1 : 0));
        $share = fn (int $count): ?string => $played > 0 ? round($count / $played * 100).'%' : null;

        $standing = Standing::query()
            ->where('league_id', $fixture->league_id)
            ->when($fixture->season_id !== null, fn ($q) => $q->where('season_id', $fixture->season_id))
            ->where('team_id', $team->id)
            ->first();

        return FootballShape::teamRef($team) + [
            'last_5' => [
                'played' => $played,
                'form' => $played > 0 ? round($points / ($played * 3) * 100).'%' : null,
                'att' => $share($results->filter(fn ($r) => $r['for'] > 0)->count()),
                'def' => $share($results->filter(fn ($r) => $r['against'] === 0)->count()),
                'goals' => [
                    'for' => [
                        'total' => (int) $results->sum('for'),
                        'average' => $played > 0 ? round($results->sum('for') / $played, 1) : 0,
                    ],
                    'against' => [
                        'total' => (int) $results->sum('against'),
                        'average' => $played > 0 ? round($results->sum('against') / $played, 1) : 0,
                    ],
                ],
            ],
            'league' => $standing === null ? null : [
                'form' => $standing->form,
                'fixtures' => [
                    'played' => ['home' => $standing->home_played, 'away' => $standing->away_played, 'total' => $standing->played],
                    'wins' => ['home' => $standing->home_win, 'away' => $standing->away_win, 'total' => $standing->win],
                    'draws' => ['home' => $standing->home_draw, 'away' => $standing->away_draw, 'total' => $standing->draw],
                    'loses' => ['home' => $standing->home_lose, 'away' => $standing->away_lose, 'total' => $standing->lose],
                ],
                'goals' => [
                    'for' => ['total' => ['home' => $standing->home_goals_for, 'away' => $standing->away_goals_for, 'total' => $standing->goals_for]],
                    'against' => ['total' => ['home' => $standing->home_goals_against, 'away' => $standing->away_goals_against, 'total' => $standing->goals_against]],
                ],
            ],
        ];
    }

    /**
     * @return Collection<int, Fixture>
     */
    private function headToHead(Fixture $fixture): Collection
    {
        if ($fixture->home_team_id === null || $fixture->away_team_id === null) {
            return collect();
        }

        return Fixture::query()
            ->with(['league.country', 'season', 'homeTeam', 'awayTeam', 'venue'])
            ->whereKeyNot($fixture->id)
            ->where('status_group', FixtureStatusGroup::Finished)
            ->where(fn ($q) => $q
                ->where(fn ($w) => $w->where('home_team_id', $fixture->home_team_id)->where('away_team_id', $fixture->away_team_id))
                ->orWhere(fn ($w) => $w->where('home_team_id', $fixture->away_team_id)->where('away_team_id', $fixture->home_team_id)))
            ->orderByDesc('match_datetime')
            ->limit(5)
            ->get();
    }
}
