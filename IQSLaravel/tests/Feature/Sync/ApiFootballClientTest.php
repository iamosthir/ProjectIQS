<?php

namespace Tests\Feature\Sync;

use App\Services\ApiFootball\ApiFootballClient;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class ApiFootballClientTest extends TestCase
{
    use RefreshDatabase;

    /**
     * API-Football rejects a `timezone` param on endpoints that don't define it
     * ("The Timezone field do not exist."), so the client must only attach it to
     * the fixtures-family endpoints that actually accept it.
     */
    public function test_timezone_is_only_sent_to_endpoints_that_accept_it(): void
    {
        Http::fake(['*' => Http::response(['response' => []], 200)]);

        $client = app(ApiFootballClient::class);

        $client->get('leagues', ['country' => 'Iraq']); // must NOT carry timezone
        $client->get('teams', ['league' => 542, 'season' => 2023]); // must NOT carry timezone
        $client->get('fixtures', ['id' => 215662]); // MUST carry timezone

        Http::assertSent(fn ($request) => str_contains($request->url(), '/leagues')
            && ! str_contains($request->url(), 'timezone'));

        Http::assertSent(fn ($request) => str_contains($request->url(), '/teams')
            && ! str_contains($request->url(), 'timezone'));

        Http::assertSent(fn ($request) => str_contains($request->url(), '/fixtures')
            && str_contains($request->url(), 'timezone'));
    }
}
