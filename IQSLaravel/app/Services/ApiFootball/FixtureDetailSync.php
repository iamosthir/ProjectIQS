<?php

namespace App\Services\ApiFootball;

use App\Models\Fixture;
use App\Models\FixtureEvent;
use App\Models\FixtureLineup;
use App\Models\FixtureLineupPlayer;
use App\Models\FixtureStatistic;
use App\Support\Enums\Source;

class FixtureDetailSync extends FootballSync
{
    /**
     * Pull events, lineups and statistics for an API-sourced fixture.
     *
     * Uses the single `GET /fixtures?id=` form, which returns the fixture WITH
     * its events, lineups and statistics embedded — one request instead of the
     * three separate `/fixtures/{events,lineups,statistics}` calls. This cuts
     * the per-fixture request budget by ~66% (important on the free 100/day
     * plan and on every finished-match poll in `sync:live`).
     */
    public function sync(Fixture $fixture): void
    {
        if ($fixture->external_id === null) {
            return; // manual fixtures are admin-maintained
        }

        $rows = $this->client->get('fixtures', ['id' => $fixture->external_id]);
        $row = $rows[0] ?? null;

        if ($row === null) {
            return; // unknown id / empty response — never wipe existing detail
        }

        $this->applyEvents($fixture, $row['events'] ?? []);
        $this->applyLineups($fixture, $row['lineups'] ?? []);
        $this->applyStatistics($fixture, $row['statistics'] ?? []);
    }

    /**
     * @param  array<int, array<string, mixed>>  $rows
     */
    protected function applyEvents(Fixture $fixture, array $rows): void
    {
        // Only replace the provider's own rows; admin-entered (manual) events
        // on this fixture are preserved.
        $fixture->events()->where('source', Source::ApiFootball)->delete();
        $order = 0;

        foreach ($rows as $event) {
            FixtureEvent::create([
                'fixture_id' => $fixture->id,
                'source' => Source::ApiFootball,
                'team_id' => $this->resolveTeamId($event['team'] ?? []),
                'player_id' => $this->resolvePlayerId($event['player'] ?? []),
                'assist_player_id' => ! empty($event['assist']['id']) ? $this->resolvePlayerId($event['assist']) : null,
                'player_name' => $event['player']['name'] ?? null,
                'assist_name' => $event['assist']['name'] ?? null,
                'elapsed' => $event['time']['elapsed'] ?? 0,
                'extra' => $event['time']['extra'] ?? null,
                'type' => $this->mapEventType((string) ($event['type'] ?? '')),
                'detail' => $event['detail'] ?? '',
                'comments' => $event['comments'] ?? null,
                'display_order' => $order++,
            ]);
        }

        $fixture->update(['has_events' => $fixture->events()->exists()]);
    }

    /**
     * @param  array<int, array<string, mixed>>  $rows
     */
    protected function applyLineups(Fixture $fixture, array $rows): void
    {
        // Teams whose lineup the admin maintains manually win over the provider
        // (the unique(fixture_id, team_id) constraint means only one lineup per
        // team, so we skip those teams instead of overwriting them).
        $manualTeamIds = $fixture->lineups()
            ->where('source', Source::Manual)
            ->pluck('team_id')
            ->all();

        $fixture->lineups()
            ->where('source', Source::ApiFootball)
            ->get()
            ->each(fn (FixtureLineup $l) => $l->players()->delete());
        $fixture->lineups()->where('source', Source::ApiFootball)->delete();

        foreach ($rows as $row) {
            $teamId = $this->resolveTeamId($row['team'] ?? []);
            if ($teamId === null || in_array($teamId, $manualTeamIds, true)) {
                continue;
            }

            $lineup = FixtureLineup::create([
                'fixture_id' => $fixture->id,
                'team_id' => $teamId,
                'source' => Source::ApiFootball,
                'formation' => $row['formation'] ?? null,
                'coach_name' => $row['coach']['name'] ?? null,
                'coach_photo' => $row['coach']['photo'] ?? null,
            ]);

            foreach ($row['startXI'] ?? [] as $entry) {
                $this->addLineupPlayer($lineup, $entry['player'] ?? [], true);
            }
            foreach ($row['substitutes'] ?? [] as $entry) {
                $this->addLineupPlayer($lineup, $entry['player'] ?? [], false);
            }
        }

        $fixture->update(['has_lineups' => $fixture->lineups()->exists()]);
    }

    /**
     * @param  array<int, array<string, mixed>>  $rows
     */
    protected function applyStatistics(Fixture $fixture, array $rows): void
    {
        $fixture->statistics()->where('source', Source::ApiFootball)->delete();

        foreach ($rows as $teamStat) {
            $teamId = $this->resolveTeamId($teamStat['team'] ?? []);
            $order = 0;

            foreach ($teamStat['statistics'] ?? [] as $stat) {
                FixtureStatistic::create([
                    'fixture_id' => $fixture->id,
                    'team_id' => $teamId,
                    'source' => Source::ApiFootball,
                    'type' => $stat['type'] ?? '',
                    'value' => $stat['value'] !== null ? (string) $stat['value'] : null,
                    'value_numeric' => $this->toNumeric($stat['value'] ?? null),
                    'display_order' => $order++,
                ]);
            }
        }

        $fixture->update(['has_statistics' => $fixture->statistics()->exists()]);
    }

    /**
     * @param  array<string, mixed>  $player
     */
    protected function addLineupPlayer(FixtureLineup $lineup, array $player, bool $starter): void
    {
        FixtureLineupPlayer::create([
            'fixture_lineup_id' => $lineup->id,
            'player_id' => $this->resolvePlayerId($player),
            'player_name' => $player['name'] ?? '',
            'number' => $player['number'] ?? null,
            'position' => $player['pos'] ?? null,
            'grid' => $player['grid'] ?? null,
            'is_starter' => $starter,
        ]);
    }

    protected function mapEventType(string $apiType): string
    {
        return match (strtolower($apiType)) {
            'goal' => 'goal',
            'card' => 'card',
            'subst' => 'subst',
            'var' => 'var',
            default => 'goal',
        };
    }

    protected function toNumeric(mixed $value): ?float
    {
        if ($value === null || $value === '') {
            return null;
        }

        $clean = str_replace('%', '', (string) $value);

        return is_numeric($clean) ? (float) $clean : null;
    }
}
