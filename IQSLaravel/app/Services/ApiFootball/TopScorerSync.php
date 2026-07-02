<?php

namespace App\Services\ApiFootball;

use App\Models\League;
use App\Models\Season;
use App\Models\TopScorer;
use App\Services\Match\TopScorerService;
use App\Support\Enums\Source;

class TopScorerSync extends FootballSync
{
    public function __construct(
        ApiFootballClient $client,
        private readonly TopScorerService $ranks,
    ) {
        parent::__construct($client);
    }

    public function sync(int $leagueExternalId, int $season): int
    {
        $leagueId = League::query()->apiFootball()->where('external_id', $leagueExternalId)->value('id');

        if ($leagueId === null) {
            return 0;
        }

        $seasonId = Season::query()->where('league_id', $leagueId)->where('year', $season)->value('id');
        $rows = $this->client->get('players/topscorers', ['league' => $leagueExternalId, 'season' => $season]);
        $count = 0;

        foreach ($rows as $row) {
            $player = $row['player'] ?? [];
            $stat = $row['statistics'][0] ?? [];
            $playerId = $this->resolvePlayerId($player);

            if ($playerId === null) {
                continue;
            }

            TopScorer::updateOrCreate(
                ['league_id' => $leagueId, 'season_id' => $seasonId, 'player_id' => $playerId],
                [
                    'source' => Source::ApiFootball,
                    'player_name' => $player['name'] ?? '',
                    'player_photo_path' => $player['photo'] ?? null,
                    'team_id' => $this->resolveTeamId($stat['team'] ?? []),
                    'team_name' => $stat['team']['name'] ?? null,
                    'goals' => $stat['goals']['total'] ?? 0,
                    'assists' => $stat['goals']['assists'] ?? null,
                    'penalties' => $stat['penalty']['scored'] ?? null,
                    'last_synced_at' => now(),
                ],
            );
            $count++;
        }

        $this->ranks->recomputeRanks($leagueId, $seasonId);

        return $count;
    }
}
