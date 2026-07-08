<?php

namespace Tests\Feature\Sync;

use App\Models\Country;
use App\Models\League;
use App\Services\ApiFootball\CountrySync;
use App\Services\ApiFootball\LeagueSync;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class ApiFootballSyncTest extends TestCase
{
    use RefreshDatabase;

    /**
     * @return array<string, mixed>
     */
    private function premier(string $name = 'Premier League'): array
    {
        return [
            'league' => ['id' => 39, 'name' => $name, 'type' => 'League', 'logo' => 'logo.png'],
            'country' => ['name' => 'England', 'code' => 'GB', 'flag' => 'flag.png'],
            'seasons' => [['year' => 2025, 'current' => true, 'start' => '2025-08-01', 'end' => '2026-05-01']],
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function payload(array $leagues): array
    {
        return ['response' => $leagues];
    }

    public function test_sync_upserts_without_creating_duplicates(): void
    {
        Http::fakeSequence()
            ->push($this->payload([$this->premier()]), 200, ['x-ratelimit-requests-remaining' => '95'])
            ->push($this->payload([$this->premier()]), 200, ['x-ratelimit-requests-remaining' => '94']);

        app(LeagueSync::class)->sync();
        app(LeagueSync::class)->sync(); // re-run

        $this->assertSame(1, League::where('external_id', 39)->count());
        $this->assertDatabaseHas('leagues', ['external_id' => 39, 'source' => 'api_football', 'name_en' => 'Premier League']);
        $this->assertDatabaseHas('seasons', ['year' => 2025, 'is_current' => true]);
    }

    public function test_locked_rows_are_never_overwritten_by_sync(): void
    {
        Http::fakeSequence()
            ->push($this->payload([$this->premier('Original')]), 200, ['x-ratelimit-requests-remaining' => '95'])
            ->push($this->payload([$this->premier('Changed Upstream')]), 200, ['x-ratelimit-requests-remaining' => '94']);

        app(LeagueSync::class)->sync();
        League::where('external_id', 39)->update(['is_locked' => true]);
        app(LeagueSync::class)->sync();

        $this->assertSame('Original', League::where('external_id', 39)->value('name_en'));
    }

    public function test_admin_arabic_override_is_preserved_on_resync(): void
    {
        Http::fakeSequence()
            ->push($this->payload([$this->premier('First')]), 200, ['x-ratelimit-requests-remaining' => '95'])
            ->push($this->payload([$this->premier('Second')]), 200, ['x-ratelimit-requests-remaining' => '94']);

        app(LeagueSync::class)->sync();
        League::where('external_id', 39)->update(['name_ar' => 'الدوري الإنجليزي']);
        app(LeagueSync::class)->sync();

        $row = League::where('external_id', 39)->first();
        $this->assertSame('الدوري الإنجليزي', $row->name_ar); // admin override kept
        $this->assertSame('Second', $row->name_en);          // English refreshed
    }

    public function test_non_iraqi_leagues_import_inactive_and_admin_activation_survives_resync(): void
    {
        Http::fakeSequence()
            ->push($this->payload([$this->premier()]), 200, ['x-ratelimit-requests-remaining' => '95'])
            ->push($this->payload([$this->premier()]), 200, ['x-ratelimit-requests-remaining' => '94']);

        app(LeagueSync::class)->sync();

        $league = League::where('external_id', 39)->firstOrFail();
        $this->assertFalse($league->is_active); // England → hidden until an admin opts in

        $league->update(['is_active' => true]); // admin activates
        app(LeagueSync::class)->sync();

        $this->assertTrue($league->refresh()->is_active); // re-sync never flips it back
    }

    public function test_iraqi_leagues_import_active_and_country_scope_reaches_the_api(): void
    {
        $row = [
            'league' => ['id' => 542, 'name' => 'Iraqi League', 'type' => 'League', 'logo' => null],
            'country' => ['name' => 'Iraq', 'code' => 'IQ', 'flag' => null],
            'seasons' => [],
        ];
        Http::fake(['*' => Http::response(['response' => [$row]], 200)]);

        app(LeagueSync::class)->sync('Iraq');

        $this->assertDatabaseHas('leagues', ['external_id' => 542, 'is_iraqi' => true, 'is_active' => true]);
        Http::assertSent(fn ($request) => str_contains($request->url(), 'country=Iraq'));
    }

    public function test_countries_sync_upserts_without_duplicates(): void
    {
        Http::fake(['*' => Http::response(['response' => [
            ['name' => 'England', 'code' => 'GB-ENG', 'flag' => 'gb-eng.svg'],
            ['name' => 'World', 'code' => null, 'flag' => null],
        ]], 200)]);

        app(CountrySync::class)->sync();
        app(CountrySync::class)->sync(); // re-run

        $this->assertSame(2, Country::count());
        $this->assertDatabaseHas('countries', [
            'name_en' => 'England', 'code' => 'GB-ENG', 'source' => 'api_football',
        ]);
    }

    public function test_every_call_is_logged(): void
    {
        Http::fake(['*' => Http::response(['response' => []], 200)]);

        app(LeagueSync::class)->sync();

        $this->assertDatabaseHas('api_football_sync_logs', [
            'endpoint' => 'leagues',
            'status' => 'success',
        ]);
    }
}
