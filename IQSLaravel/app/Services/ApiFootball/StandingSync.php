<?php

namespace App\Services\ApiFootball;

use App\Models\League;
use App\Models\Season;
use App\Models\Standing;
use App\Support\Enums\Source;

class StandingSync extends FootballSync
{
    public function sync(int $leagueExternalId, int $season): int
    {
        $rows = $this->client->get('standings', ['league' => $leagueExternalId, 'season' => $season]);

        if ($rows === []) {
            return 0;
        }

        $leagueId = League::query()->apiFootball()->where('external_id', $leagueExternalId)->value('id');

        if ($leagueId === null) {
            return 0;
        }

        $seasonId = Season::query()->where('league_id', $leagueId)->where('year', $season)->value('id')
            ?? Season::create([
                'league_id' => $leagueId,
                'source' => Source::ApiFootball,
                'year' => $season,
                'is_current' => true,
            ])->id;

        $groups = $rows[0]['league']['standings'] ?? [];
        $count = 0;

        foreach ($groups as $group) {
            foreach ($group as $row) {
                $teamId = $this->resolveTeamId($row['team'] ?? []);

                if ($teamId === null) {
                    continue;
                }

                Standing::updateOrCreate(
                    [
                        'league_id' => $leagueId,
                        'season_id' => $seasonId,
                        'team_id' => $teamId,
                        'group_label' => $row['group'] ?? '',
                    ],
                    [
                        'source' => Source::ApiFootball,
                        'rank' => $row['rank'] ?? 0,
                        'points' => $row['points'] ?? 0,
                        'goals_diff' => $row['goalsDiff'] ?? 0,
                        'played' => $row['all']['played'] ?? 0,
                        'win' => $row['all']['win'] ?? 0,
                        'draw' => $row['all']['draw'] ?? 0,
                        'lose' => $row['all']['lose'] ?? 0,
                        'goals_for' => $row['all']['goals']['for'] ?? 0,
                        'goals_against' => $row['all']['goals']['against'] ?? 0,
                        'home_played' => $row['home']['played'] ?? 0,
                        'home_win' => $row['home']['win'] ?? 0,
                        'home_draw' => $row['home']['draw'] ?? 0,
                        'home_lose' => $row['home']['lose'] ?? 0,
                        'home_goals_for' => $row['home']['goals']['for'] ?? 0,
                        'home_goals_against' => $row['home']['goals']['against'] ?? 0,
                        'away_played' => $row['away']['played'] ?? 0,
                        'away_win' => $row['away']['win'] ?? 0,
                        'away_draw' => $row['away']['draw'] ?? 0,
                        'away_lose' => $row['away']['lose'] ?? 0,
                        'away_goals_for' => $row['away']['goals']['for'] ?? 0,
                        'away_goals_against' => $row['away']['goals']['against'] ?? 0,
                        'form' => $row['form'] ?? null,
                        'status' => $row['status'] ?? null,
                        'description' => $row['description'] ?? null,
                        'display_order' => $row['rank'] ?? 0,
                        'last_synced_at' => now(),
                    ],
                );
                $count++;
            }
        }

        return $count;
    }
}
