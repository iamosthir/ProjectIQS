<?php

namespace App\Support\Football;

use App\Models\FixtureEvent;
use App\Models\FixtureLineup;
use App\Models\League;
use App\Models\Season;
use App\Models\Team;
use App\Support\Enums\FixtureStatusGroup;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;

/**
 * Computes the API-Football `teams/statistics` payload from our own fixtures,
 * events and lineups — the same way the upstream API derives it. Only played
 * (finished) fixtures count towards results; minute tables come from goal and
 * card events.
 */
class TeamSeasonStatistics
{
    private const MINUTE_BUCKETS = ['0-15', '16-30', '31-45', '46-60', '61-75', '76-90', '91-105', '106-120'];

    private const OVER_UNDER_LINES = ['0.5', '1.5', '2.5', '3.5', '4.5'];

    /**
     * @return array<string, mixed>
     */
    public static function build(Team $team, League $league, Season $season, ?Carbon $until = null): array
    {
        $fixtures = $season->fixtures()
            ->where(fn ($q) => $q->where('home_team_id', $team->id)->orWhere('away_team_id', $team->id))
            ->where('status_group', FixtureStatusGroup::Finished)
            ->when($until !== null, fn ($q) => $q->where('match_datetime', '<=', $until))
            ->orderBy('match_datetime')
            ->get();

        $fixtureIds = $fixtures->pluck('id');

        $events = FixtureEvent::query()
            ->whereIn('fixture_id', $fixtureIds)
            ->get()
            ->groupBy('team_id');

        $teamEvents = $events->get($team->id, collect());

        $goalMinutesFor = self::minuteTable(
            $teamEvents->filter(fn ($e) => $e->type?->value === 'goal' && $e->detail !== 'Missed Penalty')
        );
        $goalMinutesAgainst = self::minuteTable(
            $events->flatten()->filter(
                fn ($e) => $e->team_id !== null && $e->team_id !== $team->id
                    && $e->type?->value === 'goal' && $e->detail !== 'Missed Penalty'
            )
        );

        $results = $fixtures->map(function ($fixture) use ($team): array {
            $isHome = $fixture->home_team_id === $team->id;
            $for = $isHome ? $fixture->home_goals : $fixture->away_goals;
            $against = $isHome ? $fixture->away_goals : $fixture->home_goals;

            return [
                'home' => $isHome,
                'for' => (int) $for,
                'against' => (int) $against,
                'outcome' => $for <=> $against, // 1 win, 0 draw, -1 lose
            ];
        });

        $home = $results->where('home', true);
        $away = $results->where('home', false);

        $formations = FixtureLineup::query()
            ->whereIn('fixture_id', $fixtureIds)
            ->where('team_id', $team->id)
            ->whereNotNull('formation')
            ->get()
            ->countBy('formation')
            ->sortDesc();

        return [
            'league' => FootballShape::leagueBlock($league, $season),
            'team' => FootballShape::teamRef($team),
            'form' => $results->map(fn ($r) => match ($r['outcome']) {
                1 => 'W', 0 => 'D', default => 'L',
            })->implode(''),
            'fixtures' => [
                'played' => self::homeAwayTotal($home->count(), $away->count()),
                'wins' => self::homeAwayTotal(
                    $home->where('outcome', 1)->count(),
                    $away->where('outcome', 1)->count()
                ),
                'draws' => self::homeAwayTotal(
                    $home->where('outcome', 0)->count(),
                    $away->where('outcome', 0)->count()
                ),
                'loses' => self::homeAwayTotal(
                    $home->where('outcome', -1)->count(),
                    $away->where('outcome', -1)->count()
                ),
            ],
            'goals' => [
                'for' => self::goalsBlock($home, $away, 'for', $goalMinutesFor, $results),
                'against' => self::goalsBlock($home, $away, 'against', $goalMinutesAgainst, $results),
            ],
            'biggest' => self::biggest($results),
            'clean_sheet' => self::homeAwayTotal(
                $home->where('against', 0)->count(),
                $away->where('against', 0)->count()
            ),
            'failed_to_score' => self::homeAwayTotal(
                $home->where('for', 0)->count(),
                $away->where('for', 0)->count()
            ),
            'penalty' => self::penalty($teamEvents),
            'lineups' => $formations->map(fn (int $played, string $formation): array => [
                'formation' => $formation,
                'played' => $played,
            ])->values()->all(),
            'cards' => [
                'yellow' => self::minuteTable(
                    $teamEvents->filter(fn ($e) => $e->type?->value === 'card' && $e->detail === 'Yellow Card')
                ),
                'red' => self::minuteTable(
                    $teamEvents->filter(fn ($e) => $e->type?->value === 'card' && $e->detail === 'Red Card')
                ),
            ],
        ];
    }

    /**
     * @return array{home: int, away: int, total: int}
     */
    private static function homeAwayTotal(int $home, int $away): array
    {
        return ['home' => $home, 'away' => $away, 'total' => $home + $away];
    }

    /**
     * @param  Collection<int, array<string, mixed>>  $home
     * @param  Collection<int, array<string, mixed>>  $away
     * @param  Collection<int, array<string, mixed>>  $all
     * @param  array<string, array<string, mixed>>  $minutes
     * @return array<string, mixed>
     */
    private static function goalsBlock(Collection $home, Collection $away, string $key, array $minutes, Collection $all): array
    {
        $homeGoals = (int) $home->sum($key);
        $awayGoals = (int) $away->sum($key);

        $average = fn (int $goals, int $played): string => $played > 0
            ? number_format($goals / $played, 1)
            : '0.0';

        $underOver = [];
        foreach (self::OVER_UNDER_LINES as $line) {
            $underOver[$line] = [
                'over' => $all->filter(fn ($r) => $r[$key] > (float) $line)->count(),
                'under' => $all->filter(fn ($r) => $r[$key] < (float) $line)->count(),
            ];
        }

        return [
            'total' => self::homeAwayTotal($homeGoals, $awayGoals),
            'average' => [
                'home' => $average($homeGoals, $home->count()),
                'away' => $average($awayGoals, $away->count()),
                'total' => $average($homeGoals + $awayGoals, $home->count() + $away->count()),
            ],
            'minute' => $minutes,
            'under_over' => $underOver,
        ];
    }

    /**
     * Bucket events into the doc's 15-minute windows with percentages.
     *
     * @param  Collection<int, FixtureEvent>  $events
     * @return array<string, array{total: int|null, percentage: string|null}>
     */
    private static function minuteTable(Collection $events): array
    {
        $counts = array_fill_keys(self::MINUTE_BUCKETS, 0);

        foreach ($events as $event) {
            $minute = (int) $event->elapsed + (int) $event->extra;
            $bucket = match (true) {
                $minute <= 15 => '0-15',
                $minute <= 30 => '16-30',
                $minute <= 45 => '31-45',
                $minute <= 60 => '46-60',
                $minute <= 75 => '61-75',
                $minute <= 90 => '76-90',
                $minute <= 105 => '91-105',
                default => '106-120',
            };
            $counts[$bucket]++;
        }

        $total = array_sum($counts);
        $table = [];

        foreach ($counts as $bucket => $count) {
            $table[$bucket] = [
                'total' => $count > 0 ? $count : null,
                'percentage' => ($count > 0 && $total > 0)
                    ? number_format($count / $total * 100, 2).'%'
                    : null,
            ];
        }

        return $table;
    }

    /**
     * @param  Collection<int, array<string, mixed>>  $results
     * @return array<string, mixed>
     */
    private static function biggest(Collection $results): array
    {
        $streaks = ['wins' => 0, 'draws' => 0, 'loses' => 0];
        $current = ['wins' => 0, 'draws' => 0, 'loses' => 0];

        foreach ($results as $result) {
            $bucket = match ($result['outcome']) {
                1 => 'wins', 0 => 'draws', default => 'loses',
            };
            foreach ($current as $key => $value) {
                $current[$key] = $key === $bucket ? $value + 1 : 0;
            }
            $streaks[$bucket] = max($streaks[$bucket], $current[$bucket]);
        }

        $score = fn ($r): string => $r['home']
            ? $r['for'].'-'.$r['against']
            : $r['against'].'-'.$r['for'];

        $bestBy = function (Collection $subset, callable $metric) use ($score): ?string {
            $best = $subset->sortByDesc($metric)->first();

            return $best !== null ? $score($best) : null;
        };

        $homeResults = $results->where('home', true);
        $awayResults = $results->where('home', false);

        return [
            'streak' => $streaks,
            'wins' => [
                'home' => $bestBy($homeResults->where('outcome', 1), fn ($r) => $r['for'] - $r['against']),
                'away' => $bestBy($awayResults->where('outcome', 1), fn ($r) => $r['for'] - $r['against']),
            ],
            'loses' => [
                'home' => $bestBy($homeResults->where('outcome', -1), fn ($r) => $r['against'] - $r['for']),
                'away' => $bestBy($awayResults->where('outcome', -1), fn ($r) => $r['against'] - $r['for']),
            ],
            'goals' => [
                'for' => [
                    'home' => (int) $homeResults->max('for'),
                    'away' => (int) $awayResults->max('for'),
                ],
                'against' => [
                    'home' => (int) $homeResults->max('against'),
                    'away' => (int) $awayResults->max('against'),
                ],
            ],
        ];
    }

    /**
     * @param  Collection<int, FixtureEvent>  $events
     * @return array<string, mixed>
     */
    private static function penalty(Collection $events): array
    {
        $scored = $events->filter(fn ($e) => $e->type?->value === 'goal' && $e->detail === 'Penalty')->count();
        $missed = $events->filter(fn ($e) => $e->detail === 'Missed Penalty')->count();
        $total = $scored + $missed;

        $percentage = fn (int $count): ?string => $total > 0
            ? number_format($count / $total * 100, 2).'%'
            : null;

        return [
            'scored' => ['total' => $scored, 'percentage' => $percentage($scored)],
            'missed' => ['total' => $missed, 'percentage' => $percentage($missed)],
            'total' => $total,
        ];
    }
}
