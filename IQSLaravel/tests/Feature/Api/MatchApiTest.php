<?php

namespace Tests\Feature\Api;

use App\Models\Fixture;
use App\Models\League;
use App\Models\Season;
use App\Models\TopScorer;
use App\Models\User;
use App\Services\Match\TopScorerService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class MatchApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Sanctum::actingAs(User::factory()->create());
    }

    public function test_leagues_index_is_ordered_by_tier(): void
    {
        League::factory()->create(['tier' => 3, 'name_en' => 'Third']);
        League::factory()->create(['tier' => 1, 'name_en' => 'First']);

        $this->getJson('/api/v1/leagues')
            ->assertOk()
            ->assertJsonPath('data.0.tier', 1)
            ->assertJsonPath('data.1.tier', 3);
    }

    public function test_manual_and_api_fixtures_share_the_same_shape(): void
    {
        Fixture::factory()->finished()->create();
        Fixture::factory()->apiFootball(123)->finished()->create();

        $response = $this->getJson('/api/v1/fixtures')->assertOk();

        $items = $response->json('data');
        $this->assertCount(2, $items);

        // Identical key sets, and crucially no `source` leaks to the app.
        $this->assertSame(array_keys($items[0]), array_keys($items[1]));
        $this->assertArrayNotHasKey('source', $items[0]);
        $this->assertArrayHasKey('score', $items[0]);
        $this->assertArrayHasKey('social', $items[0]);
    }

    public function test_fixture_detail_returns_full_structure(): void
    {
        $fixture = Fixture::factory()->create();

        $this->getJson("/api/v1/fixtures/{$fixture->id}")
            ->assertOk()
            ->assertJsonStructure([
                'data' => [
                    'id', 'league', 'status', 'home', 'away', 'score',
                    'officials' => ['referee', 'assistant_1', 'supervisor'],
                    'broadcasts', 'events', 'lineups', 'statistics',
                    'social' => ['likes', 'comments', 'shares', 'liked_by_me'],
                    'prediction' => ['total', 'home_percent', 'draw_percent', 'away_percent', 'is_open', 'my_prediction'],
                ],
            ]);
    }

    public function test_live_endpoint_returns_only_live_fixtures(): void
    {
        Fixture::factory()->live()->create();
        Fixture::factory()->create(); // scheduled

        $this->getJson('/api/v1/fixtures/live')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.status.group', 'live');
    }

    public function test_top_scorers_are_ranked_by_goals(): void
    {
        $league = League::factory()->create();
        TopScorer::factory()->for($league)->create(['player_name' => 'Low', 'goals' => 5]);
        TopScorer::factory()->for($league)->create(['player_name' => 'High', 'goals' => 12]);
        TopScorer::factory()->for($league)->create(['player_name' => 'Mid', 'goals' => 9]);

        app(TopScorerService::class)->recomputeRanks($league->id, null);

        $this->getJson("/api/v1/leagues/{$league->id}/top-scorers")
            ->assertOk()
            ->assertJsonPath('data.0.player.name', 'High')
            ->assertJsonPath('data.0.rank', 1)
            ->assertJsonPath('data.2.player.name', 'Low');
    }

    public function test_featured_leagues_are_listed_first(): void
    {
        League::factory()->create(['tier' => 1, 'name_en' => 'Plain', 'is_featured' => false]);
        League::factory()->create(['tier' => 3, 'name_en' => 'Featured', 'is_featured' => true]);

        $this->getJson('/api/v1/leagues')
            ->assertOk()
            ->assertJsonPath('data.0.name', 'Featured')
            ->assertJsonPath('data.1.name', 'Plain');
    }

    public function test_league_detail_lists_its_seasons_newest_first(): void
    {
        $league = League::factory()->create();
        Season::factory()->for($league)->create(['year' => 2024, 'is_current' => false]);
        Season::factory()->for($league)->create(['year' => 2025, 'is_current' => true]);

        $this->getJson("/api/v1/leagues/{$league->id}")
            ->assertOk()
            ->assertJsonCount(2, 'data.seasons')
            ->assertJsonPath('data.seasons.0.year', 2025)
            ->assertJsonPath('data.seasons.0.is_current', true)
            ->assertJsonPath('data.seasons.1.year', 2024);
    }

    public function test_league_fixtures_filter_by_season_year(): void
    {
        $league = League::factory()->create();
        $old = Season::factory()->for($league)->create(['year' => 2024, 'is_current' => false]);
        $current = Season::factory()->for($league)->create(['year' => 2025, 'is_current' => true]);
        $oldFixture = Fixture::factory()->for($league)->create(['season_id' => $old->id]);
        $currentFixture = Fixture::factory()->for($league)->create(['season_id' => $current->id]);

        // No param → all fixtures of the league (back-compat).
        $this->getJson("/api/v1/leagues/{$league->id}/fixtures")
            ->assertOk()
            ->assertJsonCount(2, 'data');

        $this->getJson("/api/v1/leagues/{$league->id}/fixtures?season=2024")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $oldFixture->id);

        $this->getJson("/api/v1/leagues/{$league->id}/fixtures?season=2025")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $currentFixture->id);

        // Unknown year → empty, not "all seasons".
        $this->getJson("/api/v1/leagues/{$league->id}/fixtures?season=1999")
            ->assertOk()
            ->assertJsonCount(0, 'data');
    }
}
