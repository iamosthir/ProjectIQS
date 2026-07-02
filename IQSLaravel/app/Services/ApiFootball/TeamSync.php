<?php

namespace App\Services\ApiFootball;

use App\Models\Team;
use App\Models\Venue;

class TeamSync extends FootballSync
{
    /**
     * Sync the teams (+ venues) of a league season.
     */
    public function sync(int $leagueExternalId, int $season): int
    {
        $rows = $this->client->get('teams', ['league' => $leagueExternalId, 'season' => $season]);
        $count = 0;

        foreach ($rows as $row) {
            $team = $row['team'] ?? [];
            $venue = $row['venue'] ?? [];
            $id = (int) ($team['id'] ?? 0);

            if ($id === 0) {
                continue;
            }

            $venueId = null;

            if (! empty($venue['id'])) {
                $venueName = (string) ($venue['name'] ?? '');
                $venueModel = $this->upsert(Venue::class, (int) $venue['id'], [
                    'name_en' => $venueName,
                    'address' => $venue['address'] ?? null,
                    'city' => $venue['city'] ?? null,
                    'capacity' => $venue['capacity'] ?? null,
                    'surface' => $venue['surface'] ?? null,
                    'image_path' => $venue['image'] ?? null,
                    'external_payload' => $venue,
                ], ['name_ar' => $venueName]);
                $venueId = $venueModel?->id;
            }

            $nameEn = (string) ($team['name'] ?? '');

            $this->upsert(Team::class, $id, [
                'name_en' => $nameEn,
                'short_code' => $team['code'] ?? null,
                'country_name' => $team['country'] ?? null,
                'founded_year' => $team['founded'] ?? null,
                'is_national' => (bool) ($team['national'] ?? false),
                'logo_path' => $team['logo'] ?? null,
                'venue_id' => $venueId,
                'external_payload' => $row,
            ], ['name_ar' => $nameEn]);

            $count++;
        }

        return $count;
    }
}
