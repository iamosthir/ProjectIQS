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
     * Sync leagues (+ their seasons). Pass a country name exactly as
     * API-Football spells it ("Iraq", "England", "World" for international
     * competitions…) to fetch only that country's leagues; null → all.
     *
     * Non-Iraqi leagues are CREATED INACTIVE so the app stays clean until an
     * admin activates the few they want (Leagues page, or automatically when
     * a season is subscribed to auto-sync). Re-syncs never flip `is_active`.
     *
     * @return int number of leagues processed
     */
    public function sync(?string $country = null): int
    {
        $rows = $this->client->get('leagues', $country !== null ? ['country' => $country] : []);
        $count = 0;

        foreach ($rows as $row) {
            $league = $row['league'] ?? [];
            $countryRow = $row['country'] ?? [];
            $id = (int) ($league['id'] ?? 0);

            if ($id === 0) {
                continue;
            }

            $nameEn = (string) ($league['name'] ?? '');
            $isIraqi = strtolower((string) ($countryRow['name'] ?? '')) === 'iraq';

            $model = $this->upsert(League::class, $id, [
                'name_en' => $nameEn,
                'type' => ($league['type'] ?? '') === 'Cup' ? LeagueType::Cup->value : LeagueType::League->value,
                'logo_path' => $league['logo'] ?? null,
                'country_name' => $countryRow['name'] ?? null,
                'country_code' => $countryRow['code'] ?? null,
                'country_flag' => $countryRow['flag'] ?? null,
                'is_iraqi' => $isIraqi,
                'category' => LeagueCategory::Other->value,
                'external_payload' => $row,
            ], ['name_ar' => $nameEn, 'is_active' => $isIraqi]);

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
