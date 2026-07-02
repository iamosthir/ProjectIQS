<?php

namespace Tests\Feature\Sync;

use App\Models\Fixture;
use App\Models\Team;
use App\Services\ApiFootball\FixtureDetailSync;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class FixtureDetailSyncTest extends TestCase
{
    use RefreshDatabase;

    /**
     * One `/fixtures?id=` response with events, lineups and statistics embedded.
     *
     * @return array<string, mixed>
     */
    private function fixtureWithDetails(): array
    {
        return [
            'fixture' => ['id' => 215662, 'status' => ['short' => 'FT', 'long' => 'Match Finished']],
            'events' => [
                ['time' => ['elapsed' => 25, 'extra' => null], 'team' => ['id' => 463, 'name' => 'Aldosivi'], 'player' => ['id' => 6126, 'name' => 'F. Andrada'], 'assist' => ['id' => null, 'name' => null], 'type' => 'Goal', 'detail' => 'Normal Goal', 'comments' => null],
                ['time' => ['elapsed' => 33, 'extra' => null], 'team' => ['id' => 442, 'name' => 'Defensa'], 'player' => ['id' => 5936, 'name' => 'J. González'], 'assist' => ['id' => null, 'name' => null], 'type' => 'Card', 'detail' => 'Yellow Card', 'comments' => null],
            ],
            'lineups' => [
                [
                    'team' => ['id' => 463, 'name' => 'Aldosivi'],
                    'formation' => '4-3-3',
                    'coach' => ['id' => 4, 'name' => 'Coach', 'photo' => 'coach.png'],
                    'startXI' => [['player' => ['id' => 617, 'name' => 'Ederson', 'number' => 31, 'pos' => 'G', 'grid' => '1:1']]],
                    'substitutes' => [['player' => ['id' => 50828, 'name' => 'Steffen', 'number' => 13, 'pos' => 'G', 'grid' => null]]],
                ],
            ],
            'statistics' => [
                ['team' => ['id' => 463, 'name' => 'Aldosivi'], 'statistics' => [
                    ['type' => 'Shots on Goal', 'value' => 3],
                    ['type' => 'Ball Possession', 'value' => '55%'],
                ]],
            ],
        ];
    }

    public function test_detail_sync_pulls_events_lineups_and_statistics_in_a_single_request(): void
    {
        $fixture = Fixture::factory()->apiFootball(215662)->create();

        Http::fake([
            '*' => Http::response(['response' => [$this->fixtureWithDetails()]], 200, ['x-ratelimit-requests-remaining' => '95']),
        ]);

        app(FixtureDetailSync::class)->sync($fixture);

        // The whole point of the refactor: ONE upstream call, /fixtures?id=215662.
        Http::assertSentCount(1);
        Http::assertSent(fn ($request) => str_contains($request->url(), '/fixtures')
            && str_contains($request->url(), 'id=215662'));

        $fixture->refresh();
        $this->assertTrue($fixture->has_events);
        $this->assertTrue($fixture->has_lineups);
        $this->assertTrue($fixture->has_statistics);

        $this->assertSame(2, $fixture->events()->count());
        $this->assertSame(1, $fixture->lineups()->count());
        $this->assertSame(2, $fixture->lineups()->first()->players()->count()); // 1 starter + 1 sub

        $this->assertDatabaseHas('fixture_statistics', [
            'fixture_id' => $fixture->id,
            'type' => 'Ball Possession',
            'value' => '55%',
            'value_numeric' => 55,
        ]);
    }

    public function test_manual_fixtures_are_skipped_without_any_request(): void
    {
        $fixture = Fixture::factory()->create(); // source=manual, external_id=null

        Http::fake();

        app(FixtureDetailSync::class)->sync($fixture);

        Http::assertNothingSent();
    }

    public function test_empty_response_does_not_wipe_existing_details(): void
    {
        $fixture = Fixture::factory()->apiFootball(215662)->create(['has_events' => true]);
        $fixture->events()->create([
            'source' => 'manual', 'type' => 'goal', 'detail' => 'Normal Goal', 'elapsed' => 10, 'display_order' => 0,
        ]);

        Http::fake(['*' => Http::response(['response' => []], 200)]);

        app(FixtureDetailSync::class)->sync($fixture);

        // Unknown id / empty response must not destroy already-stored detail.
        $this->assertSame(1, $fixture->events()->count());
    }

    public function test_sync_preserves_admin_entered_manual_detail_alongside_api_rows(): void
    {
        $fixture = Fixture::factory()->apiFootball(215662)->create();

        // Admin-entered detail on this API fixture.
        $fixture->events()->create([
            'source' => 'manual', 'type' => 'goal', 'detail' => 'Normal Goal', 'elapsed' => 5, 'display_order' => 0,
        ]);
        $fixture->statistics()->create([
            'source' => 'manual', 'team_id' => $fixture->home_team_id, 'type' => 'Expected Goals', 'value' => '1.7', 'display_order' => 0,
        ]);
        $manual = $fixture->lineups()->create([
            'source' => 'manual', 'team_id' => $fixture->home_team_id, 'formation' => '4-4-2',
        ]);
        $manual->players()->create(['player_name' => 'Custom XI', 'is_starter' => true]);

        Http::fake(['*' => Http::response(['response' => [$this->fixtureWithDetails()]], 200)]);
        app(FixtureDetailSync::class)->sync($fixture);

        // Manual rows survive the re-sync.
        $this->assertSame(1, $fixture->events()->where('source', 'manual')->count());
        $this->assertSame(1, $fixture->statistics()->where('source', 'manual')->count());
        $this->assertSame(1, $fixture->lineups()->where('source', 'manual')->count());

        // Provider rows are (re)built alongside them.
        $this->assertSame(2, $fixture->events()->where('source', 'api_football')->count());
        $this->assertSame(2, $fixture->statistics()->where('source', 'api_football')->count());
        $this->assertSame(1, $fixture->lineups()->where('source', 'api_football')->count());
    }

    public function test_manual_lineup_wins_over_api_for_the_same_team(): void
    {
        $fixture = Fixture::factory()->apiFootball(215662)->create();

        // The provider response's lineup is for team external_id 463; pre-seed
        // that canonical team so the admin's manual lineup targets the same row.
        $team = Team::factory()->create(['source' => 'api_football', 'external_id' => 463]);
        $fixture->lineups()->create([
            'source' => 'manual', 'team_id' => $team->id, 'formation' => 'MANUAL',
        ]);

        Http::fake(['*' => Http::response(['response' => [$this->fixtureWithDetails()]], 200)]);
        app(FixtureDetailSync::class)->sync($fixture);

        $lineup = $fixture->lineups()->where('team_id', $team->id)->first();
        $this->assertSame('manual', $lineup->source->value);
        $this->assertSame('MANUAL', $lineup->formation);
        // The provider lineup for this team was skipped, not duplicated.
        $this->assertSame(1, $fixture->lineups()->count());
    }
}
