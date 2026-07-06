<?php

namespace App\Support\Football;

use App\Models\Coach;
use App\Models\Country;
use App\Models\Fixture;
use App\Models\FixtureEvent;
use App\Models\FixtureLineup;
use App\Models\FixturePlayerStatistic;
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
use App\Models\Venue;
use App\Support\Localize;
use Illuminate\Support\Collection;

/**
 * Builders that shape our Eloquent models into the exact `response` item
 * structures of API-Football v3 (see "API-Football - Documentation.md").
 * The mobile /api/v1/football/* endpoints wrap these in the standard
 * {success,message,data,meta} envelope; `data` mirrors the upstream payload.
 *
 * Names resolve through {@see Localize} so Accept-Language keeps working;
 * image fields return the stored storage-relative path (the app renders them
 * through assetUrl(), same as every other endpoint).
 */
class FootballShape
{
    /**
     * @return array<string, mixed>
     */
    public static function country(Country $country): array
    {
        return [
            'id' => $country->id,
            'name' => Localize::pick($country->name_ar, $country->name_en),
            'code' => $country->code,
            'flag' => $country->flag_path,
        ];
    }

    /**
     * `leagues` item: {league, country, seasons[]}.
     *
     * @return array<string, mixed>
     */
    public static function league(League $league): array
    {
        return [
            'league' => [
                'id' => $league->id,
                'name' => Localize::pick($league->name_ar, $league->name_en),
                'type' => $league->type?->value,
                'logo' => $league->logo_path,
            ],
            'country' => [
                'name' => $league->country !== null
                    ? Localize::pick($league->country->name_ar, $league->country->name_en)
                    : $league->country_name,
                'code' => $league->country?->code ?? $league->country_code,
                'flag' => $league->country?->flag_path ?? $league->country_flag,
            ],
            'seasons' => $league->seasons
                ->sortBy('year')
                ->values()
                ->map(fn (Season $season): array => [
                    'year' => $season->year,
                    'start' => $season->start_date?->toDateString(),
                    'end' => $season->end_date?->toDateString(),
                    'current' => $season->is_current,
                    'coverage' => $season->coverage,
                ])
                ->all(),
        ];
    }

    /**
     * Embedded league block used by fixtures/standings/statistics payloads.
     *
     * @return array<string, mixed>
     */
    public static function leagueBlock(?League $league, ?Season $season, ?string $round = null): array
    {
        $block = [
            'id' => $league?->id,
            'name' => $league !== null ? Localize::pick($league->name_ar, $league->name_en) : null,
            'country' => $league?->country !== null
                ? Localize::pick($league->country->name_ar, $league->country->name_en)
                : $league?->country_name,
            'logo' => $league?->logo_path,
            'flag' => $league?->country?->flag_path ?? $league?->country_flag,
            'season' => $season?->year,
        ];

        if ($round !== null) {
            $block['round'] = $round;
        }

        return $block;
    }

    /**
     * Minimal {id,name,logo} team reference.
     *
     * @return array<string, mixed>
     */
    public static function teamRef(?Team $team): array
    {
        return [
            'id' => $team?->id,
            'name' => $team !== null ? Localize::pick($team->name_ar, $team->name_en) : null,
            'logo' => $team?->logo_path,
        ];
    }

    /**
     * `teams` item: {team, venue}.
     *
     * @return array<string, mixed>
     */
    public static function team(Team $team): array
    {
        return [
            'team' => [
                'id' => $team->id,
                'name' => Localize::pick($team->name_ar, $team->name_en),
                'code' => $team->short_code,
                'country' => $team->country !== null
                    ? Localize::pick($team->country->name_ar, $team->country->name_en)
                    : $team->country_name,
                'founded' => $team->founded_year,
                'national' => $team->is_national,
                'logo' => $team->logo_path,
            ],
            'venue' => $team->venue !== null ? self::venue($team->venue) : null,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public static function venue(Venue $venue): array
    {
        return [
            'id' => $venue->id,
            'name' => Localize::pick($venue->name_ar, $venue->name_en),
            'address' => $venue->address,
            'city' => $venue->city,
            'country' => $venue->country !== null
                ? Localize::pick($venue->country->name_ar, $venue->country->name_en)
                : $venue->country_name,
            'capacity' => $venue->capacity,
            'surface' => $venue->surface,
            'image' => $venue->image_path,
        ];
    }

    /**
     * `fixtures` item: {fixture, league, teams, goals, score}.
     *
     * @return array<string, mixed>
     */
    public static function fixture(Fixture $fixture): array
    {
        return [
            'fixture' => [
                'id' => $fixture->id,
                'referee' => $fixture->referee,
                'timezone' => $fixture->timezone,
                'date' => $fixture->match_datetime?->toIso8601String(),
                'timestamp' => $fixture->match_datetime?->getTimestamp(),
                'periods' => [
                    'first' => $fixture->period_first_at?->getTimestamp(),
                    'second' => $fixture->period_second_at?->getTimestamp(),
                ],
                'venue' => [
                    'id' => $fixture->venue?->id,
                    'name' => $fixture->venue !== null
                        ? Localize::pick($fixture->venue->name_ar, $fixture->venue->name_en)
                        : null,
                    'city' => $fixture->venue?->city,
                ],
                'status' => [
                    'long' => $fixture->status_long,
                    'short' => $fixture->status_short,
                    'elapsed' => $fixture->elapsed,
                    'extra' => $fixture->status_extra,
                ],
            ],
            'league' => self::leagueBlock($fixture->league, $fixture->season, $fixture->round),
            'teams' => [
                'home' => self::teamRef($fixture->homeTeam) + [
                    'winner' => $fixture->winner?->value === null ? null : $fixture->winner->value === 'home',
                ],
                'away' => self::teamRef($fixture->awayTeam) + [
                    'winner' => $fixture->winner?->value === null ? null : $fixture->winner->value === 'away',
                ],
            ],
            'goals' => [
                'home' => $fixture->home_goals,
                'away' => $fixture->away_goals,
            ],
            'score' => [
                'halftime' => ['home' => $fixture->home_ht, 'away' => $fixture->away_ht],
                'fulltime' => ['home' => $fixture->home_ft, 'away' => $fixture->away_ft],
                'extratime' => ['home' => $fixture->home_et, 'away' => $fixture->away_et],
                'penalty' => ['home' => $fixture->home_pen, 'away' => $fixture->away_pen],
            ],
        ];
    }

    /**
     * `standings` row.
     *
     * @return array<string, mixed>
     */
    public static function standingRow(Standing $standing): array
    {
        return [
            'rank' => $standing->rank,
            'team' => self::teamRef($standing->team),
            'points' => $standing->points,
            'goalsDiff' => $standing->goals_diff,
            'group' => $standing->group_label !== '' ? $standing->group_label : null,
            'form' => $standing->form,
            'status' => $standing->status,
            'description' => $standing->description,
            'all' => [
                'played' => $standing->played,
                'win' => $standing->win,
                'draw' => $standing->draw,
                'lose' => $standing->lose,
                'goals' => ['for' => $standing->goals_for, 'against' => $standing->goals_against],
            ],
            'home' => [
                'played' => $standing->home_played,
                'win' => $standing->home_win,
                'draw' => $standing->home_draw,
                'lose' => $standing->home_lose,
                'goals' => ['for' => $standing->home_goals_for, 'against' => $standing->home_goals_against],
            ],
            'away' => [
                'played' => $standing->away_played,
                'win' => $standing->away_win,
                'draw' => $standing->away_draw,
                'lose' => $standing->away_lose,
                'goals' => ['for' => $standing->away_goals_for, 'against' => $standing->away_goals_against],
            ],
            'update' => $standing->updated_at?->toIso8601String(),
        ];
    }

    /**
     * `standings` response item: league block + rows grouped per group label.
     *
     * @param  Collection<int, Standing>  $rows
     * @return array<string, mixed>
     */
    public static function standings(League $league, ?Season $season, Collection $rows): array
    {
        $groups = $rows
            ->groupBy('group_label')
            ->map(fn (Collection $group) => $group->sortBy('rank')->values()->map(
                fn (Standing $standing): array => self::standingRow($standing)
            )->all())
            ->values()
            ->all();

        return [
            'league' => self::leagueBlock($league, $season) + ['standings' => $groups],
        ];
    }

    /**
     * `fixtures/events` item.
     *
     * @return array<string, mixed>
     */
    public static function event(FixtureEvent $event): array
    {
        return [
            'time' => [
                'elapsed' => $event->elapsed,
                'extra' => $event->extra,
            ],
            'team' => self::teamRef($event->team),
            'player' => [
                'id' => $event->player_id,
                'name' => $event->player !== null
                    ? Localize::pick($event->player->name_ar, $event->player->name_en)
                    : $event->player_name,
            ],
            'assist' => [
                'id' => $event->assist_player_id,
                'name' => $event->assistPlayer !== null
                    ? Localize::pick($event->assistPlayer->name_ar, $event->assistPlayer->name_en)
                    : $event->assist_name,
            ],
            'type' => match ($event->type?->value) {
                'goal' => 'Goal',
                'card' => 'Card',
                'var' => 'Var',
                default => $event->type?->value,
            },
            'detail' => $event->detail,
            'comments' => $event->comments,
        ];
    }

    /**
     * `fixtures/lineups` item.
     *
     * @return array<string, mixed>
     */
    public static function lineup(FixtureLineup $lineup): array
    {
        $mapPlayer = fn ($row): array => [
            'player' => [
                'id' => $row->player_id,
                'name' => $row->player !== null
                    ? Localize::pick($row->player->name_ar, $row->player->name_en)
                    : $row->player_name,
                'number' => $row->number,
                'pos' => $row->position,
                'grid' => $row->grid,
            ],
        ];

        [$startXI, $substitutes] = $lineup->players->partition(fn ($row) => $row->is_starter);

        return [
            'team' => self::teamRef($lineup->team) + ['colors' => $lineup->colors],
            'formation' => $lineup->formation,
            'startXI' => $startXI->values()->map($mapPlayer)->all(),
            'substitutes' => $substitutes->values()->map($mapPlayer)->all(),
            'coach' => [
                'id' => $lineup->coach_id,
                'name' => $lineup->coach !== null
                    ? Localize::pick($lineup->coach->name_ar, $lineup->coach->name_en)
                    : $lineup->coach_name,
                'photo' => $lineup->coach?->photo_path ?? $lineup->coach_photo,
            ],
        ];
    }

    /**
     * `fixtures/players` statistics block for one player row.
     *
     * @return array<string, mixed>
     */
    public static function fixturePlayerStatistics(FixturePlayerStatistic $row): array
    {
        return [
            'player' => [
                'id' => $row->player_id,
                'name' => $row->player !== null
                    ? Localize::pick($row->player->name_ar, $row->player->name_en)
                    : $row->player_name,
                'photo' => $row->player?->photo_path,
            ],
            'statistics' => [[
                'games' => [
                    'minutes' => $row->minutes,
                    'number' => $row->number,
                    'position' => $row->position,
                    'rating' => $row->rating !== null ? (string) $row->rating : null,
                    'captain' => $row->captain,
                    'substitute' => $row->substitute,
                ],
                'offsides' => $row->offsides,
                'shots' => ['total' => $row->shots_total, 'on' => $row->shots_on],
                'goals' => [
                    'total' => $row->goals_total,
                    'conceded' => $row->goals_conceded,
                    'assists' => $row->goals_assists,
                    'saves' => $row->goals_saves,
                ],
                'passes' => [
                    'total' => $row->passes_total,
                    'key' => $row->passes_key,
                    'accuracy' => $row->passes_accuracy,
                ],
                'tackles' => [
                    'total' => $row->tackles_total,
                    'blocks' => $row->tackles_blocks,
                    'interceptions' => $row->tackles_interceptions,
                ],
                'duels' => ['total' => $row->duels_total, 'won' => $row->duels_won],
                'dribbles' => [
                    'attempts' => $row->dribbles_attempts,
                    'success' => $row->dribbles_success,
                    'past' => $row->dribbles_past,
                ],
                'fouls' => ['drawn' => $row->fouls_drawn, 'committed' => $row->fouls_committed],
                'cards' => ['yellow' => $row->cards_yellow, 'red' => $row->cards_red],
                'penalty' => [
                    'won' => $row->penalty_won,
                    'commited' => $row->penalty_committed,
                    'scored' => $row->penalty_scored,
                    'missed' => $row->penalty_missed,
                    'saved' => $row->penalty_saved,
                ],
            ]],
        ];
    }

    /**
     * `players/profiles` player block.
     *
     * @return array<string, mixed>
     */
    public static function playerProfile(Player $player): array
    {
        return [
            'id' => $player->id,
            'name' => Localize::pick($player->name_ar, $player->name_en),
            'firstname' => $player->firstname,
            'lastname' => $player->lastname,
            'age' => $player->date_of_birth?->age,
            'birth' => [
                'date' => $player->date_of_birth?->toDateString(),
                'place' => $player->birth_place,
                'country' => $player->birth_country,
            ],
            'nationality' => $player->nationality,
            'height' => $player->height,
            'weight' => $player->weight,
            'injured' => $player->is_injured,
            'number' => $player->number,
            'position' => $player->position,
            'photo' => $player->photo_path,
        ];
    }

    /**
     * `players` season statistics block (one entry of `statistics[]`).
     *
     * @return array<string, mixed>
     */
    public static function playerSeasonStatistics(PlayerStatistic $row): array
    {
        return [
            'team' => self::teamRef($row->team),
            'league' => self::leagueBlock($row->league, $row->season),
            'games' => [
                'appearences' => $row->appearances,
                'lineups' => $row->lineups,
                'minutes' => $row->minutes,
                'number' => $row->number,
                'position' => $row->position,
                'rating' => $row->rating !== null ? (string) $row->rating : null,
                'captain' => $row->captain,
            ],
            'substitutes' => [
                'in' => $row->substitutes_in,
                'out' => $row->substitutes_out,
                'bench' => $row->substitutes_bench,
            ],
            'shots' => ['total' => $row->shots_total, 'on' => $row->shots_on],
            'goals' => [
                'total' => $row->goals_total,
                'conceded' => $row->goals_conceded,
                'assists' => $row->goals_assists,
                'saves' => $row->goals_saves,
            ],
            'passes' => [
                'total' => $row->passes_total,
                'key' => $row->passes_key,
                'accuracy' => $row->passes_accuracy,
            ],
            'tackles' => [
                'total' => $row->tackles_total,
                'blocks' => $row->tackles_blocks,
                'interceptions' => $row->tackles_interceptions,
            ],
            'duels' => ['total' => $row->duels_total, 'won' => $row->duels_won],
            'dribbles' => [
                'attempts' => $row->dribbles_attempts,
                'success' => $row->dribbles_success,
                'past' => $row->dribbles_past,
            ],
            'fouls' => ['drawn' => $row->fouls_drawn, 'committed' => $row->fouls_committed],
            'cards' => [
                'yellow' => $row->cards_yellow,
                'yellowred' => $row->cards_yellowred,
                'red' => $row->cards_red,
            ],
            'penalty' => [
                'won' => $row->penalty_won,
                'commited' => $row->penalty_committed,
                'scored' => $row->penalty_scored,
                'missed' => $row->penalty_missed,
                'saved' => $row->penalty_saved,
            ],
        ];
    }

    /**
     * `players` item: {player, statistics[]}.
     *
     * @param  Collection<int, PlayerStatistic>  $statistics
     * @return array<string, mixed>
     */
    public static function playerWithStatistics(Player $player, Collection $statistics): array
    {
        return [
            'player' => self::playerProfile($player),
            'statistics' => $statistics
                ->map(fn (PlayerStatistic $row): array => self::playerSeasonStatistics($row))
                ->all(),
        ];
    }

    /**
     * `coachs` item.
     *
     * @return array<string, mixed>
     */
    public static function coach(Coach $coach): array
    {
        return [
            'id' => $coach->id,
            'name' => Localize::pick($coach->name_ar, $coach->name_en),
            'firstname' => $coach->firstname,
            'lastname' => $coach->lastname,
            'age' => $coach->date_of_birth?->age,
            'birth' => [
                'date' => $coach->date_of_birth?->toDateString(),
                'place' => $coach->birth_place,
                'country' => $coach->birth_country,
            ],
            'nationality' => $coach->nationality,
            'height' => $coach->height,
            'weight' => $coach->weight,
            'photo' => $coach->photo_path,
            'team' => $coach->team !== null ? self::teamRef($coach->team) : null,
            'career' => $coach->careers->map(fn ($career): array => [
                'team' => $career->team !== null
                    ? self::teamRef($career->team)
                    : ['id' => null, 'name' => $career->team_name, 'logo' => null],
                'start' => $career->start_date?->toDateString(),
                'end' => $career->end_date?->toDateString(),
            ])->all(),
        ];
    }

    /**
     * `injuries` item.
     *
     * @return array<string, mixed>
     */
    public static function injury(Injury $injury): array
    {
        return [
            'player' => [
                'id' => $injury->player_id,
                'name' => $injury->player !== null
                    ? Localize::pick($injury->player->name_ar, $injury->player->name_en)
                    : null,
                'photo' => $injury->player?->photo_path,
                'type' => $injury->type,
                'reason' => $injury->reason,
            ],
            'team' => self::teamRef($injury->team),
            'fixture' => [
                'id' => $injury->fixture_id,
                'timezone' => $injury->fixture?->timezone,
                'date' => $injury->fixture?->match_datetime?->toIso8601String()
                    ?? $injury->date?->toDateString(),
                'timestamp' => $injury->fixture?->match_datetime?->getTimestamp(),
            ],
            'league' => self::leagueBlock($injury->league, $injury->season),
        ];
    }

    /**
     * `transfers` item for one player (moves grouped under `transfers[]`).
     *
     * @param  Collection<int, Transfer>  $transfers
     * @return array<string, mixed>
     */
    public static function transfers(Player $player, Collection $transfers): array
    {
        return [
            'player' => [
                'id' => $player->id,
                'name' => Localize::pick($player->name_ar, $player->name_en),
            ],
            'update' => $transfers->max('updated_at')?->toIso8601String(),
            'transfers' => $transfers
                ->sortByDesc('transfer_date')
                ->values()
                ->map(fn (Transfer $transfer): array => [
                    'date' => $transfer->transfer_date?->toDateString(),
                    'type' => $transfer->type,
                    'teams' => [
                        'in' => self::teamRef($transfer->teamIn),
                        'out' => self::teamRef($transfer->teamOut),
                    ],
                ])->all(),
        ];
    }

    /**
     * `trophies` item.
     *
     * @return array<string, mixed>
     */
    public static function trophy(Trophy $trophy): array
    {
        return [
            'league' => $trophy->league_name,
            'country' => $trophy->country,
            'season' => $trophy->season,
            'place' => $trophy->place,
        ];
    }

    /**
     * `sidelined` item.
     *
     * @return array<string, mixed>
     */
    public static function sidelined(Sidelined $sidelined): array
    {
        return [
            'type' => $sidelined->type,
            'start' => $sidelined->start_date?->toDateString(),
            'end' => $sidelined->end_date?->toDateString(),
        ];
    }
}
