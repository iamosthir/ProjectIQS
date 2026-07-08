<?php

namespace Tests\Feature\Sync;

use App\Models\Fixture;
use App\Models\League;
use App\Models\Season;
use App\Models\Team;
use App\Support\Enums\Source;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class AutoSyncTest extends TestCase
{
    use RefreshDatabase;

    /**
     * @return array<string, mixed>
     */
    private function fixtureRow(int $id = 1001, string $status = 'NS', ?int $elapsed = null, ?string $date = null, int $league = 39): array
    {
        return [
            'fixture' => [
                'id' => $id,
                'referee' => 'Ali Sabah',
                'timezone' => 'UTC',
                'date' => $date ?? now()->addDays(2)->toIso8601String(),
                'venue' => ['id' => 555, 'name' => 'People Stadium', 'city' => 'Baghdad'],
                'status' => ['long' => 'Not Started', 'short' => $status, 'elapsed' => $elapsed],
            ],
            'league' => ['id' => $league, 'season' => 2025, 'round' => 'Round 1'],
            'teams' => [
                'home' => ['id' => 10, 'name' => 'Home FC', 'logo' => null, 'winner' => null],
                'away' => ['id' => 20, 'name' => 'Away FC', 'logo' => null, 'winner' => null],
            ],
            'goals' => ['home' => null, 'away' => null],
            'score' => [
                'halftime' => ['home' => null, 'away' => null],
                'fulltime' => ['home' => null, 'away' => null],
                'extratime' => ['home' => null, 'away' => null],
                'penalty' => ['home' => null, 'away' => null],
            ],
        ];
    }

    /**
     * @return array{league: League, season: Season}
     */
    private function subscribe(bool $autoSync = true): array
    {
        $league = League::factory()->apiFootball(39)->create();
        $season = Season::factory()->for($league)->create([
            'source' => Source::ApiFootball,
            'year' => 2025,
            'auto_sync' => $autoSync,
        ]);

        return ['league' => $league, 'season' => $season];
    }

    private function fakeSeasonEndpoints(): void
    {
        Http::fake([
            '*/standings*' => Http::response(['response' => [[
                'league' => ['id' => 39, 'standings' => [[[
                    'rank' => 1,
                    'team' => ['id' => 10, 'name' => 'Home FC'],
                    'points' => 3,
                    'goalsDiff' => 2,
                    'group' => 'Regular Season',
                    'all' => ['played' => 1, 'win' => 1, 'draw' => 0, 'lose' => 0, 'goals' => ['for' => 2, 'against' => 0]],
                ]]]],
            ]]]),
            '*/teams*' => Http::response(['response' => [[
                'team' => ['id' => 10, 'name' => 'Home FC', 'country' => 'Iraq', 'founded' => 1950, 'national' => false, 'logo' => null],
                'venue' => ['id' => 555, 'name' => 'People Stadium', 'city' => 'Baghdad'],
            ]]]),
            '*/players/topscorers*' => Http::response(['response' => [[
                'player' => ['id' => 77, 'name' => 'Star Striker', 'photo' => null],
                'statistics' => [[
                    'team' => ['id' => 10, 'name' => 'Home FC'],
                    'goals' => ['total' => 5, 'assists' => 2],
                    'penalty' => ['scored' => 1],
                ]],
            ]]]),
            '*/fixtures*' => Http::response(['response' => [$this->fixtureRow()]]),
        ]);
    }

    public function test_auto_sync_populates_a_subscribed_season_and_sets_watermarks(): void
    {
        ['season' => $season] = $this->subscribe();
        $this->fakeSeasonEndpoints();

        $this->artisan('sync:auto')->assertSuccessful();

        $fixture = Fixture::query()->apiFootball()->where('external_id', 1001)->first();
        $this->assertNotNull($fixture);
        $this->assertSame($season->id, $fixture->season_id);

        $this->assertDatabaseHas('standings', ['league_id' => $season->league_id, 'season_id' => $season->id, 'rank' => 1]);
        $this->assertDatabaseHas('teams', ['source' => 'api_football', 'external_id' => 10]);
        $this->assertDatabaseHas('top_scorers', ['league_id' => $season->league_id, 'goals' => 5]);

        $season->refresh();
        $this->assertNotNull($season->fixtures_synced_at);
        $this->assertNotNull($season->standings_synced_at);
        $this->assertNotNull($season->teams_synced_at);
        $this->assertNotNull($season->top_scorers_synced_at);
    }

    public function test_auto_sync_is_idempotent_and_self_paces_between_ticks(): void
    {
        $this->subscribe();
        $this->fakeSeasonEndpoints();

        $this->artisan('sync:auto')->assertSuccessful();
        $this->artisan('sync:auto')->assertSuccessful(); // immediate second tick

        // One row per external id, and the fresh watermarks meant no tier was
        // due again — the second tick sent zero requests.
        $this->assertSame(1, Fixture::query()->where('external_id', 1001)->count());
        $this->assertCount(4, Http::recorded());
    }

    public function test_auto_sync_ignores_unsubscribed_seasons(): void
    {
        $this->subscribe(autoSync: false);
        Http::fake();

        $this->artisan('sync:auto')->assertSuccessful();

        Http::assertNothingSent();
        $this->assertDatabaseCount('fixtures', 0);
    }

    public function test_live_sync_skips_the_api_when_no_fixture_is_in_the_live_window(): void
    {
        $this->subscribe();
        Http::fake();

        $this->artisan('sync:live')->assertSuccessful();

        Http::assertNothingSent();
    }

    public function test_auto_sync_backfills_details_for_finished_fixtures_once(): void
    {
        ['season' => $season] = $this->subscribe();
        $home = Team::factory()->create(['source' => Source::ApiFootball, 'external_id' => 10]);
        $away = Team::factory()->create(['source' => Source::ApiFootball, 'external_id' => 20]);

        $fixture = Fixture::create([
            'source' => Source::ApiFootball,
            'external_id' => 1001,
            'league_id' => $season->league_id,
            'season_id' => $season->id,
            'home_team_id' => $home->id,
            'away_team_id' => $away->id,
            'match_datetime' => now()->subDays(3),
            'status_short' => 'FT',
            'status_group' => 'finished',
        ]);

        // Fresh watermarks → no tier requests; only the backfill runs.
        $season->forceFill([
            'fixtures_synced_at' => now(), 'standings_synced_at' => now(),
            'teams_synced_at' => now(), 'top_scorers_synced_at' => now(),
        ])->save();

        $detailRow = $this->fixtureRow(status: 'FT', date: now()->subDays(3)->toIso8601String()) + [
            'events' => [[
                'time' => ['elapsed' => 40, 'extra' => null],
                'team' => ['id' => 10, 'name' => 'Home FC'],
                'player' => ['id' => 77, 'name' => 'Star Striker'],
                'assist' => ['id' => null, 'name' => null],
                'type' => 'Goal',
                'detail' => 'Normal Goal',
            ]],
            'lineups' => [],
            'statistics' => [],
        ];
        Http::fake(['*' => Http::response(['response' => [$detailRow]])]);

        $this->artisan('sync:auto')->assertSuccessful();

        $fixture->refresh();
        $this->assertNotNull($fixture->details_synced_at);
        $this->assertTrue($fixture->has_events);
        $this->assertDatabaseHas('fixture_events', ['fixture_id' => $fixture->id, 'elapsed' => 40]);

        // Second tick: the stamp prevents any re-request.
        $this->artisan('sync:auto')->assertSuccessful();
        $this->assertCount(1, Http::recorded());
    }

    public function test_live_sync_ignores_fixtures_of_inactive_leagues(): void
    {
        League::factory()->apiFootball(40)->create(['is_active' => false]);

        Http::fake(['*' => Http::response(['response' => [
            $this->fixtureRow(status: '1H', elapsed: 20, league: 40),
        ]])]);

        $this->artisan('sync:live', ['--force' => true])->assertSuccessful();

        $this->assertDatabaseCount('fixtures', 0);
    }

    public function test_live_sync_refreshes_in_play_details_for_subscribed_fixtures(): void
    {
        ['season' => $season] = $this->subscribe();
        $home = Team::factory()->create(['source' => Source::ApiFootball, 'external_id' => 10]);
        $away = Team::factory()->create(['source' => Source::ApiFootball, 'external_id' => 20]);

        $fixture = Fixture::create([
            'source' => Source::ApiFootball,
            'external_id' => 1001,
            'league_id' => $season->league_id,
            'season_id' => $season->id,
            'home_team_id' => $home->id,
            'away_team_id' => $away->id,
            'match_datetime' => now()->subMinutes(30),
            'status_short' => '1H',
            'status_group' => 'live',
        ]);

        $liveRow = $this->fixtureRow(status: '2H', elapsed: 60, date: now()->subMinutes(30)->toIso8601String());
        $detailRow = $liveRow + [
            'events' => [[
                'time' => ['elapsed' => 12, 'extra' => null],
                'team' => ['id' => 10, 'name' => 'Home FC'],
                'player' => ['id' => 77, 'name' => 'Star Striker'],
                'assist' => ['id' => null, 'name' => null],
                'type' => 'Goal',
                'detail' => 'Normal Goal',
            ]],
            'lineups' => [],
            'statistics' => [],
        ];

        Http::fake(function (Request $request) use ($liveRow, $detailRow) {
            if (str_contains($request->url(), 'live=')) {
                return Http::response(['response' => [$liveRow]]);
            }

            return Http::response(['response' => [$detailRow]]);
        });

        $this->artisan('sync:live')->assertSuccessful();

        $fixture->refresh();
        $this->assertSame(60, $fixture->elapsed);
        $this->assertTrue($fixture->has_events);
        $this->assertDatabaseHas('fixture_events', ['fixture_id' => $fixture->id, 'type' => 'goal', 'elapsed' => 12]);
    }
}
