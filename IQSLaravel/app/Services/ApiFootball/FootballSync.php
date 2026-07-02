<?php

namespace App\Services\ApiFootball;

use App\Models\Player;
use App\Models\Team;
use App\Models\Venue;
use App\Support\Enums\Source;
use Illuminate\Database\Eloquent\Model;

/**
 * Base for the API-Football sync services. Provides a canonical upsert that
 * keys on (source = api_football, external_id), skips `is_locked` rows, and
 * never clobbers admin Arabic overrides (`*_ar`) on existing rows.
 */
abstract class FootballSync
{
    public function __construct(protected readonly ApiFootballClient $client) {}

    /**
     * Upsert an API-sourced row.
     *
     * @param  class-string<Model>  $modelClass
     * @param  array<string, mixed>  $attributes  English/neutral columns to (re)write every sync
     * @param  array<string, mixed>  $seedOnCreate  columns set only on first insert (e.g. `name_ar`)
     */
    protected function upsert(string $modelClass, int $externalId, array $attributes, array $seedOnCreate = []): ?Model
    {
        /** @var Model $model */
        $model = $modelClass::firstOrNew([
            'source' => Source::ApiFootball->value,
            'external_id' => $externalId,
        ]);

        // Respect admin locks — never overwrite a pinned row.
        if ($model->exists && (bool) ($model->getAttribute('is_locked') ?? false)) {
            return $model;
        }

        $wasNew = ! $model->exists;

        $model->fill($attributes);
        $model->setAttribute('source', Source::ApiFootball->value);
        $model->setAttribute('external_id', $externalId);
        $model->setAttribute('last_synced_at', now());

        if ($wasNew) {
            foreach ($seedOnCreate as $column => $value) {
                $model->setAttribute($column, $value);
            }
        }

        $model->save();

        return $model;
    }

    /**
     * Resolve a local team id, upserting a minimal record if it isn't synced
     * yet so dependent rows (fixtures, standings, scorers) are never dropped.
     *
     * @param  array<string, mixed>  $team
     */
    protected function resolveTeamId(array $team): ?int
    {
        $id = (int) ($team['id'] ?? 0);

        if ($id === 0) {
            return null;
        }

        $name = (string) ($team['name'] ?? 'Unknown');

        return $this->upsert(Team::class, $id, [
            'name_en' => $name,
            'logo_path' => $team['logo'] ?? null,
        ], ['name_ar' => $name])?->id;
    }

    /**
     * @param  array<string, mixed>  $venue
     */
    protected function resolveVenueId(array $venue): ?int
    {
        $id = (int) ($venue['id'] ?? 0);

        if ($id === 0) {
            return null;
        }

        $name = (string) ($venue['name'] ?? 'Unknown');

        return $this->upsert(Venue::class, $id, [
            'name_en' => $name,
            'city' => $venue['city'] ?? null,
        ], ['name_ar' => $name])?->id;
    }

    /**
     * @param  array<string, mixed>  $player
     */
    protected function resolvePlayerId(array $player): ?int
    {
        $id = (int) ($player['id'] ?? 0);

        if ($id === 0) {
            return null;
        }

        $name = (string) ($player['name'] ?? 'Unknown');

        return $this->upsert(Player::class, $id, [
            'name_en' => $name,
            'photo_path' => $player['photo'] ?? null,
        ], ['name_ar' => $name])?->id;
    }
}
