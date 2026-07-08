<?php

namespace App\Services\ApiFootball;

use App\Models\Country;
use App\Support\Enums\Source;

/**
 * Syncs the API-Football `countries` list (name/code/flag — the upstream
 * payload has no id, so rows key on `(source, name_en)`). Feeds the Sync
 * Console's country picker for scoped league imports; ~one request total.
 */
class CountrySync extends FootballSync
{
    public function sync(): int
    {
        $rows = $this->client->get('countries');
        $count = 0;

        foreach ($rows as $row) {
            $name = (string) ($row['name'] ?? '');

            if ($name === '') {
                continue;
            }

            $country = Country::query()
                ->where('source', Source::ApiFootball)
                ->where('name_en', $name)
                ->first();

            // Respect admin locks, and never overwrite an Arabic override.
            if ($country !== null && $country->is_locked) {
                $count++;

                continue;
            }

            if ($country === null) {
                $country = new Country([
                    'source' => Source::ApiFootball->value,
                    'name_ar' => $name,
                    'name_en' => $name,
                ]);
            }

            $country->fill([
                'code' => $row['code'] ?? null,
                'flag_path' => $row['flag'] ?? null,
                'external_payload' => $row,
                'last_synced_at' => now(),
            ])->save();

            $count++;
        }

        return $count;
    }
}
