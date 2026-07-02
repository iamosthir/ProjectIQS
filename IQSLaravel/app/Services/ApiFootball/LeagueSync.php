<?php

namespace App\Services\ApiFootball;

use App\Models\League;
use App\Models\Season;
use App\Support\Enums\LeagueCategory;
use App\Support\Enums\LeagueType;
use App\Support\Enums\Source;

class LeagueSync extends FootballSync
{
    /**
     * Sync leagues (+ their seasons). Pass $iraqiOnly to fetch only Iraq.
     *
     * @return int number of leagues processed
     */
    public function sync(bool $iraqiOnly = false): int
    {
        $rows = $this->client->get('leagues', $iraqiOnly ? ['country' => 'Iraq'] : []);
        $count = 0;

        foreach ($rows as $row) {
            $league = $row['league'] ?? [];
            $country = $row['country'] ?? [];
            $id = (int) ($league['id'] ?? 0);

            if ($id === 0) {
                continue;
            }

            $nameEn = (string) ($league['name'] ?? '');

            $model = $this->upsert(League::class, $id, [
                'name_en' => $nameEn,
                'type' => ($league['type'] ?? '') === 'Cup' ? LeagueType::Cup->value : LeagueType::League->value,
                'logo_path' => $league['logo'] ?? null,
                'country_name' => $country['name'] ?? null,
                'country_code' => $country['code'] ?? null,
                'country_flag' => $country['flag'] ?? null,
                'is_iraqi' => strtolower((string) ($country['name'] ?? '')) === 'iraq',
                'category' => LeagueCategory::Other->value,
                'external_payload' => $row,
            ], ['name_ar' => $nameEn]);

            if ($model instanceof League) {
                $this->syncSeasons($model, $row['seasons'] ?? []);
                $count++;
            }
        }

        return $count;
    }

    /**
     * @param  array<int, array<string, mixed>>  $seasons
     */
    protected function syncSeasons(League $league, array $seasons): void
    {
        foreach ($seasons as $season) {
            $year = (int) ($season['year'] ?? 0);

            if ($year === 0) {
                continue;
            }

            Season::updateOrCreate(
                ['league_id' => $league->id, 'year' => $year],
                [
                    'source' => Source::ApiFootball,
                    'label' => $year.'-'.($year + 1),
                    'start_date' => $season['start'] ?? null,
                    'end_date' => $season['end'] ?? null,
                    'is_current' => (bool) ($season['current'] ?? false),
                    'coverage' => $season['coverage'] ?? null,
                ],
            );
        }
    }
}
