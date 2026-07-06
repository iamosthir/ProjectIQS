<?php

namespace Tests\Feature\Api;

use App\Models\Coach;
use App\Models\Country;
use App\Models\Fixture;
use App\Models\FixtureEvent;
use App\Models\FixtureForecast;
use App\Models\FixturePlayerStatistic;
use App\Models\FixtureStatistic;
use App\Models\Injury;
use App\Models\League;
use App\Models\Player;
use App\Models\PlayerStatistic;
use App\Models\Season;
use App\Models\Sidelined;
use App\Models\Standing;
use App\Models\Team;
use App\Models\Transfer;
use App\Models\Trophy;
use App\Models\User;
use App\Models\Venue;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Covers the /api/v1/football/* endpoints that mirror the API-Football v3
 * documentation (payload shapes, filters and required-parameter rules).
 */
class FootballApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Sanctum::actingAs(User::factory()->create());
    }

    public function test_football_routes_require_authentication(): void
    {
        auth()->guard('sanctum')->forgetUser();

        $this->flushHeaders();

        $this->getJson('/api/v1/football/leagues')->assertUnauthorized();
    }

    public function test_countries_index_supports_code_filter(): void
    {
        Country::factory()->create(['name_en' => 'Iraq', 'code' => 'IQ']);
        Country::factory()->create(['name_en' => 'England', 'code' => 'GB']);

        $this->getJson('/api/v1/football/countries?code=iq')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.code', 'IQ')
            ->assertJsonStructure(['data' => [['id', 'name', 'code', 'flag']]]);
    }

    public function test_leagues_returns_api_football_shape_with_seasons(): void
    {
        $country = Country::factory()->create(['name_en' => 'Iraq', 'code' => 'IQ']);
        $league = League::factory()->create(['country_id' => $country->id]);
        Season::factory()->create(['league_id' => $league->id, 'year' => 2025, 'is_current' => true]);

        $this->getJson('/api/v1/football/leagues?id='.$league->id)
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonStructure([
                'data' => [[
                    'league' => ['id', 'name', 'type', 'logo'],
                    'country' => ['name', 'code', 'flag'],
                    'seasons' => [['year', 'start', 'end', 'current', 'coverage']],
                ]],
            ])
            ->assertJsonPath('data.0.league.id', $league->id)
            ->assertJsonPath('data.0.country.code', 'IQ')
            ->assertJsonPath('data.0.seasons.0.year', 2025);
    }

    public function test_leagues_seasons_lists_distinct_years(): void
    {
        Season::factory()->create(['year' => 2024]);
        Season::factory()->create(['year' => 2025]);
        Season::factory()->create(['year' => 2025]);

        $this->getJson('/api/v1/football/leagues/seasons')
            ->assertOk()
            ->assertJsonPath('data', [2024, 2025]);
    }

    public function test_teams_index_filters_by_league_and_season(): void
    {
        $league = League::factory()->create();
        $season = Season::factory()->create(['league_id' => $league->id, 'year' => 2025]);
        $fixture = Fixture::factory()->create(['league_id' => $league->id, 'season_id' => $season->id]);
        Team::factory()->create(['name_en' => 'Unrelated']);

        $response = $this->getJson('/api/v1/football/teams?league='.$league->id.'&season=2025')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonStructure([
                'data' => [[
                    'team' => ['id', 'name', 'code', 'country', 'founded', 'national', 'logo'],
                    'venue',
                ]],
            ]);

        $ids = collect($response->json('data'))->pluck('team.id');
        $this->assertEqualsCanonicalizing(
            [$fixture->home_team_id, $fixture->away_team_id],
            $ids->all(),
        );
    }

    public function test_teams_statistics_computes_results_from_fixtures(): void
    {
        $league = League::factory()->create();
        $season = Season::factory()->create(['league_id' => $league->id, 'year' => 2025]);
        $team = Team::factory()->create();

        // One home win 2-1, one away loss 0-3.
        Fixture::factory()->finished(2, 1)->create([
            'league_id' => $league->id, 'season_id' => $season->id, 'home_team_id' => $team->id,
        ]);
        Fixture::factory()->finished(3, 0)->create([
            'league_id' => $league->id, 'season_id' => $season->id, 'away_team_id' => $team->id,
        ]);

        $this->getJson("/api/v1/football/teams/statistics?league={$league->id}&season=2025&team={$team->id}")
            ->assertOk()
            ->assertJsonPath('data.form', 'WL')
            ->assertJsonPath('data.fixtures.played.total', 2)
            ->assertJsonPath('data.fixtures.wins.home', 1)
            ->assertJsonPath('data.fixtures.loses.away', 1)
            ->assertJsonPath('data.goals.for.total.total', 2)
            ->assertJsonPath('data.goals.against.total.total', 4)
            ->assertJsonPath('data.clean_sheet.total', 0)
            ->assertJsonPath('data.failed_to_score.away', 1);
    }

    public function test_venues_search_matches_city(): void
    {
        Venue::factory()->create(['city' => 'Baghdad']);
        Venue::factory()->create(['city' => 'Basra']);

        $this->getJson('/api/v1/football/venues?search=Baghd')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonStructure(['data' => [['id', 'name', 'address', 'city', 'country', 'capacity', 'surface', 'image']]]);
    }

    public function test_standings_groups_rows_under_league_block(): void
    {
        $league = League::factory()->create();
        $season = Season::factory()->create(['league_id' => $league->id, 'year' => 2025, 'is_current' => true]);
        Standing::factory()->count(2)->sequence(['rank' => 2], ['rank' => 1])->create([
            'league_id' => $league->id,
            'season_id' => $season->id,
        ]);

        $this->getJson('/api/v1/football/standings?league='.$league->id.'&season=2025')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.league.season', 2025)
            ->assertJsonPath('data.0.league.standings.0.0.rank', 1)
            ->assertJsonStructure([
                'data' => [[
                    'league' => ['id', 'name', 'country', 'logo', 'flag', 'season', 'standings'],
                ]],
            ]);
    }

    public function test_standings_requires_league_or_team(): void
    {
        $this->getJson('/api/v1/football/standings')->assertStatus(422);
    }

    public function test_fixtures_filters_by_status_and_returns_doc_shape(): void
    {
        Fixture::factory()->finished()->create();
        Fixture::factory()->create(); // NS

        $this->getJson('/api/v1/football/fixtures?status=ft')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.fixture.status.short', 'FT')
            ->assertJsonStructure([
                'data' => [[
                    'fixture' => ['id', 'referee', 'timezone', 'date', 'timestamp', 'periods', 'venue', 'status'],
                    'league' => ['id', 'name', 'country', 'logo', 'flag', 'season', 'round'],
                    'teams' => ['home' => ['id', 'name', 'logo', 'winner'], 'away'],
                    'goals' => ['home', 'away'],
                    'score' => ['halftime', 'fulltime', 'extratime', 'penalty'],
                ]],
            ]);
    }

    public function test_fixtures_live_all_returns_only_live(): void
    {
        Fixture::factory()->live()->create();
        Fixture::factory()->create();

        $this->getJson('/api/v1/football/fixtures?live=all')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.fixture.status.short', '2H');
    }

    public function test_fixtures_rounds_lists_distinct_rounds(): void
    {
        $league = League::factory()->create();
        $season = Season::factory()->create(['league_id' => $league->id, 'year' => 2025]);
        Fixture::factory()->count(2)->create([
            'league_id' => $league->id, 'season_id' => $season->id, 'round' => 'Regular Season - 1',
        ]);
        Fixture::factory()->create([
            'league_id' => $league->id, 'season_id' => $season->id, 'round' => 'Regular Season - 2',
        ]);

        $this->getJson('/api/v1/football/fixtures/rounds?league='.$league->id.'&season=2025')
            ->assertOk()
            ->assertJsonCount(2, 'data');
    }

    public function test_head_to_head_returns_meetings_between_two_teams(): void
    {
        $teamA = Team::factory()->create();
        $teamB = Team::factory()->create();
        Fixture::factory()->finished()->create(['home_team_id' => $teamA->id, 'away_team_id' => $teamB->id]);
        Fixture::factory()->finished()->create(); // unrelated

        $this->getJson("/api/v1/football/fixtures/headtohead?h2h={$teamA->id}-{$teamB->id}")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.teams.home.id', $teamA->id);
    }

    public function test_fixture_events_shape_matches_doc(): void
    {
        $fixture = Fixture::factory()->finished()->create();
        FixtureEvent::factory()->create([
            'fixture_id' => $fixture->id,
            'team_id' => $fixture->home_team_id,
            'type' => 'goal',
            'detail' => 'Normal Goal',
            'elapsed' => 25,
        ]);

        $this->getJson('/api/v1/football/fixtures/events?fixture='.$fixture->id)
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.type', 'Goal')
            ->assertJsonPath('data.0.time.elapsed', 25)
            ->assertJsonStructure(['data' => [['time', 'team', 'player', 'assist', 'type', 'detail', 'comments']]]);
    }

    public function test_fixture_statistics_grouped_by_team(): void
    {
        $fixture = Fixture::factory()->finished()->create();
        FixtureStatistic::factory()->create([
            'fixture_id' => $fixture->id,
            'team_id' => $fixture->home_team_id,
            'type' => 'Ball Possession',
            'value' => '61%',
        ]);

        $this->getJson('/api/v1/football/fixtures/statistics?fixture='.$fixture->id)
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.statistics.0.type', 'Ball Possession')
            ->assertJsonPath('data.0.statistics.0.value', '61%');
    }

    public function test_fixture_players_returns_per_player_statistics(): void
    {
        $fixture = Fixture::factory()->finished()->create();
        FixturePlayerStatistic::factory()->create([
            'fixture_id' => $fixture->id,
            'team_id' => $fixture->home_team_id,
            'minutes' => 90,
            'goals_total' => 1,
        ]);

        $this->getJson('/api/v1/football/fixtures/players?fixture='.$fixture->id)
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.players.0.statistics.0.games.minutes', 90)
            ->assertJsonPath('data.0.players.0.statistics.0.goals.total', 1)
            ->assertJsonStructure([
                'data' => [[
                    'team' => ['id', 'name', 'logo', 'update'],
                    'players' => [['player', 'statistics']],
                ]],
            ]);
    }

    public function test_injuries_requires_a_parameter_and_filters_by_fixture(): void
    {
        $this->getJson('/api/v1/football/injuries')->assertStatus(422);

        $fixture = Fixture::factory()->create();
        Injury::factory()->create(['fixture_id' => $fixture->id]);
        Injury::factory()->create();

        $this->getJson('/api/v1/football/injuries?fixture='.$fixture->id)
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonStructure(['data' => [['player' => ['id', 'name', 'photo', 'type', 'reason'], 'team', 'fixture', 'league']]]);
    }

    public function test_predictions_returns_forecast_and_computed_blocks(): void
    {
        $fixture = Fixture::factory()->create();
        FixtureForecast::factory()->create([
            'fixture_id' => $fixture->id,
            'winner_team_id' => $fixture->home_team_id,
            'advice' => 'Double chance',
            'percent_home' => 50,
            'percent_draw' => 30,
            'percent_away' => 20,
        ]);

        $this->getJson('/api/v1/football/predictions?fixture='.$fixture->id)
            ->assertOk()
            ->assertJsonPath('data.0.predictions.winner.id', $fixture->home_team_id)
            ->assertJsonPath('data.0.predictions.percent.home', '50%')
            ->assertJsonStructure([
                'data' => [[
                    'predictions' => ['winner', 'win_or_draw', 'under_over', 'goals', 'advice', 'percent'],
                    'league', 'teams' => ['home', 'away'], 'comparison', 'h2h',
                ]],
            ]);
    }

    public function test_coachs_returns_career_entries(): void
    {
        $coach = Coach::factory()->create();
        $coach->careers()->create(['team_name' => 'Old Club', 'start_date' => '2020-01-01', 'end_date' => '2022-06-30']);

        $this->getJson('/api/v1/football/coachs?id='.$coach->id)
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.career.0.team.name', 'Old Club')
            ->assertJsonStructure(['data' => [['id', 'name', 'firstname', 'lastname', 'age', 'birth', 'nationality', 'height', 'weight', 'photo', 'team', 'career']]]);
    }

    public function test_players_returns_profile_with_season_statistics(): void
    {
        $statistic = PlayerStatistic::factory()->create(['goals_total' => 7]);

        $this->getJson('/api/v1/football/players?id='.$statistic->player_id)
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.player.id', $statistic->player_id)
            ->assertJsonPath('data.0.statistics.0.goals.total', 7)
            ->assertJsonStructure([
                'data' => [[
                    'player' => ['id', 'name', 'firstname', 'lastname', 'age', 'birth', 'nationality', 'height', 'weight', 'injured', 'photo'],
                    'statistics' => [['team', 'league', 'games', 'substitutes', 'shots', 'goals', 'passes', 'tackles', 'duels', 'dribbles', 'fouls', 'cards', 'penalty']],
                ]],
            ]);
    }

    public function test_players_requires_a_filter(): void
    {
        $this->getJson('/api/v1/football/players')->assertStatus(422);
    }

    public function test_top_scorers_ranked_by_goals_within_league_season(): void
    {
        $league = League::factory()->create();
        $season = Season::factory()->create(['league_id' => $league->id, 'year' => 2025, 'is_current' => true]);

        PlayerStatistic::factory()->create(['league_id' => $league->id, 'season_id' => $season->id, 'goals_total' => 5]);
        PlayerStatistic::factory()->create(['league_id' => $league->id, 'season_id' => $season->id, 'goals_total' => 12]);
        PlayerStatistic::factory()->create(['goals_total' => 30]); // other league

        $this->getJson('/api/v1/football/players/topscorers?league='.$league->id)
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.statistics.0.goals.total', 12)
            ->assertJsonPath('data.1.statistics.0.goals.total', 5);
    }

    public function test_transfers_grouped_by_player(): void
    {
        $player = Player::factory()->create();
        Transfer::factory()->count(2)->create(['player_id' => $player->id]);

        $this->getJson('/api/v1/football/transfers?player='.$player->id)
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonCount(2, 'data.0.transfers')
            ->assertJsonStructure(['data' => [['player' => ['id', 'name'], 'update', 'transfers' => [['date', 'type', 'teams' => ['in', 'out']]]]]]);
    }

    public function test_trophies_and_sidelined_require_person_filter(): void
    {
        $this->getJson('/api/v1/football/trophies')->assertStatus(422);
        $this->getJson('/api/v1/football/sidelined')->assertStatus(422);

        $player = Player::factory()->create();
        Trophy::factory()->create(['player_id' => $player->id, 'place' => 'Winner']);
        Sidelined::factory()->create(['player_id' => $player->id, 'type' => 'Suspended']);

        $this->getJson('/api/v1/football/trophies?player='.$player->id)
            ->assertOk()
            ->assertJsonPath('data.0.place', 'Winner')
            ->assertJsonStructure(['data' => [['league', 'country', 'season', 'place']]]);

        $this->getJson('/api/v1/football/sidelined?player='.$player->id)
            ->assertOk()
            ->assertJsonPath('data.0.type', 'Suspended')
            ->assertJsonStructure(['data' => [['type', 'start', 'end']]]);
    }

    public function test_players_squads_returns_active_squad(): void
    {
        $team = Team::factory()->create();
        $player = Player::factory()->create();
        $team->players()->attach($player->id, ['number' => 10, 'position' => 'Attacker', 'is_active' => true]);

        $this->getJson('/api/v1/football/players/squads?team='.$team->id)
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.team.id', $team->id)
            ->assertJsonPath('data.0.players.0.number', 10)
            ->assertJsonStructure(['data' => [['team', 'players' => [['id', 'name', 'age', 'number', 'position', 'photo']]]]]);
    }
}
