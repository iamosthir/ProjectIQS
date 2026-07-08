<?php

namespace App\Services\ApiFootball;

use App\Models\Fixture;
use App\Models\League;
use App\Models\Season;
use App\Support\Enums\FixtureStatusGroup;
use App\Support\Enums\Source;
use Illuminate\Support\Carbon;

class FixtureSync extends FootballSync
{
    /**
     * Memoized `league_id:year` → season id lookups for the current run.
     *
     * @var array<string, int|null>
     */
    private array $seasonIds = [];

    /**
     * Sync all fixtures of a league season.
     */
    public function syncSeason(int $leagueExternalId, int $season): int
    {
        return $this->upsertFixtures(
            $this->client->get('fixtures', ['league' => $leagueExternalId, 'season' => $season])
        );
    }

    /**
     * Sync every currently-live fixture (the `sync:live` poll target).
     *
     * @return array{processed: int, kickoff: list<int>, goals: list<int>, finished: list<int>}
     */
    public function syncLive(): array
    {
        $rows = $this->client->get('fixtures', ['live' => 'all']);
        $kickoff = [];
        $goals = [];
        $finished = [];

        // `live=all` is global — only store fixtures of ACTIVE leagues so an
        // all-countries league import (inactive by default) doesn't flood the
        // fixtures table with every live match on the planet.
        $processed = $this->upsertFixtures($rows, activeLeaguesOnly: true, after: function (Fixture $fixture, array $old) use (&$kickoff, &$goals, &$finished): void {
            $new = $fixture->status_group?->value;
            $newGoals = (int) ($fixture->home_goals ?? 0) + (int) ($fixture->away_goals ?? 0);

            if ($old['status_group'] !== 'live' && $new === 'live') {
                $kickoff[] = $fixture->id;
            }
            if ($new === 'live' && $newGoals > $old['goals']) {
                $goals[] = $fixture->id;
            }
            if ($old['status_group'] !== 'finished' && $new === 'finished') {
                $finished[] = $fixture->id;
            }
        });

        return ['processed' => $processed, 'kickoff' => $kickoff, 'goals' => $goals, 'finished' => $finished];
    }

    /**
     * @param  array<int, array<string, mixed>>  $rows
     * @param  callable(Fixture, array{status_group: ?string, goals: int}):void|null  $after
     * @param  bool  $activeLeaguesOnly  skip fixtures whose league is inactive (live poll)
     */
    protected function upsertFixtures(array $rows, ?callable $after = null, bool $activeLeaguesOnly = false): int
    {
        $count = 0;

        foreach ($rows as $row) {
            $fx = $row['fixture'] ?? [];
            $lg = $row['league'] ?? [];
            $teams = $row['teams'] ?? [];
            $goals = $row['goals'] ?? [];
            $score = $row['score'] ?? [];
            $id = (int) ($fx['id'] ?? 0);

            if ($id === 0) {
                continue;
            }

            $leagueId = League::query()->apiFootball()
                ->when($activeLeaguesOnly, fn ($q) => $q->where('is_active', true))
                ->where('external_id', $lg['id'] ?? 0)
                ->value('id');
            $homeId = $this->resolveTeamId($teams['home'] ?? []);
            $awayId = $this->resolveTeamId($teams['away'] ?? []);

            if ($leagueId === null || $homeId === null || $awayId === null) {
                continue;
            }

            // Capture prior state to detect kickoff / goal / full-time transitions.
            $existing = Fixture::query()->apiFootball()->where('external_id', $id)
                ->first(['status_group', 'home_goals', 'away_goals']);
            $old = [
                'status_group' => $existing?->status_group?->value,
                'goals' => (int) ($existing->home_goals ?? 0) + (int) ($existing->away_goals ?? 0),
            ];

            $statusShort = (string) ($fx['status']['short'] ?? 'NS');

            /** @var Fixture|null $fixture */
            $fixture = $this->upsert(Fixture::class, $id, [
                'league_id' => $leagueId,
                'season_id' => $this->resolveSeasonId($leagueId, $lg['season'] ?? null),
                'home_team_id' => $homeId,
                'away_team_id' => $awayId,
                'venue_id' => $this->resolveVenueId($fx['venue'] ?? []),
                'round' => $lg['round'] ?? null,
                'referee' => $fx['referee'] ?? null,
                'match_datetime' => isset($fx['date']) ? Carbon::parse($fx['date']) : now(),
                'timezone' => $fx['timezone'] ?? 'UTC',
                'status_short' => $statusShort,
                'status_long' => $fx['status']['long'] ?? null,
                'status_group' => FixtureStatusGroup::fromApiShort($statusShort)->value,
                'elapsed' => $fx['status']['elapsed'] ?? null,
                'home_goals' => $goals['home'] ?? null,
                'away_goals' => $goals['away'] ?? null,
                'home_ht' => $score['halftime']['home'] ?? null,
                'away_ht' => $score['halftime']['away'] ?? null,
                'home_ft' => $score['fulltime']['home'] ?? null,
                'away_ft' => $score['fulltime']['away'] ?? null,
                'home_et' => $score['extratime']['home'] ?? null,
                'away_et' => $score['extratime']['away'] ?? null,
                'home_pen' => $score['penalty']['home'] ?? null,
                'away_pen' => $score['penalty']['away'] ?? null,
                'winner' => $this->resolveWinner($teams),
                'external_payload' => $row,
            ]);

            if ($fixture instanceof Fixture) {
                $count++;
                if ($after !== null) {
                    $after($fixture, $old);
                }
            }
        }

        return $count;
    }

    /**
     * Map the payload's `league.season` year onto our seasons table,
     * creating the row when the season hasn't been imported yet so the
     * fixture ↔ season linkage never silently drops.
     */
    protected function resolveSeasonId(int $leagueId, mixed $year): ?int
    {
        $year = (int) ($year ?? 0);

        if ($year === 0) {
            return null;
        }

        $key = $leagueId.':'.$year;

        if (! array_key_exists($key, $this->seasonIds)) {
            $this->seasonIds[$key] = Season::query()
                ->where('league_id', $leagueId)
                ->where('year', $year)
                ->value('id')
                ?? Season::create([
                    'league_id' => $leagueId,
                    'source' => Source::ApiFootball,
                    'year' => $year,
                ])->id;
        }

        return $this->seasonIds[$key];
    }

    /**
     * @param  array<string, mixed>  $teams
     */
    protected function resolveWinner(array $teams): ?string
    {
        $home = $teams['home']['winner'] ?? null;
        $away = $teams['away']['winner'] ?? null;

        return match (true) {
            $home === true => 'home',
            $away === true => 'away',
            $home === false && $away === false => 'draw',
            default => null,
        };
    }
}
