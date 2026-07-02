<?php

namespace Database\Factories;

use App\Models\League;
use App\Models\Team;
use App\Support\Enums\FixtureStatusGroup;
use App\Support\Enums\MatchWinner;
use App\Support\Enums\Source;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<\App\Models\Fixture>
 */
class FixtureFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'source' => Source::Manual,
            'external_id' => null,
            'league_id' => League::factory(),
            'home_team_id' => Team::factory(),
            'away_team_id' => Team::factory(),
            'round' => 'Regular Season - '.fake()->numberBetween(1, 30),
            'match_datetime' => now()->addDays(fake()->numberBetween(1, 14)),
            'status_short' => 'NS',
            'status_long' => 'Not Started',
            'status_group' => FixtureStatusGroup::Scheduled,
        ];
    }

    public function apiFootball(int $externalId): static
    {
        return $this->state(fn () => [
            'source' => Source::ApiFootball,
            'external_id' => $externalId,
            'last_synced_at' => now(),
        ]);
    }

    public function live(int $home = 1, int $away = 0): static
    {
        return $this->state(fn () => [
            'status_short' => '2H',
            'status_long' => 'Second Half',
            'status_group' => FixtureStatusGroup::Live,
            'elapsed' => 67,
            'home_goals' => $home,
            'away_goals' => $away,
            'match_datetime' => now()->subHour(),
        ]);
    }

    public function finished(int $home = 2, int $away = 1): static
    {
        return $this->state(fn () => [
            'status_short' => 'FT',
            'status_long' => 'Match Finished',
            'status_group' => FixtureStatusGroup::Finished,
            'home_goals' => $home,
            'away_goals' => $away,
            'home_ft' => $home,
            'away_ft' => $away,
            'winner' => MatchWinner::fromScores($home, $away),
            'match_datetime' => now()->subDays(1),
        ]);
    }
}
