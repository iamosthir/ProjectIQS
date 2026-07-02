<?php

namespace Tests\Feature\Api;

use App\Models\Fixture;
use App\Models\League;
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
}
