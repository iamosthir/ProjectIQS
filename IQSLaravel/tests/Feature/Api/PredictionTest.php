<?php

namespace Tests\Feature\Api;

use App\Jobs\SettleFixturePredictionsJob;
use App\Models\Fixture;
use App\Models\FixturePrediction;
use App\Models\User;
use App\Support\Enums\PredictionOutcome;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PredictionTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_predict_before_kickoff_and_summary_reflects_it(): void
    {
        Sanctum::actingAs(User::factory()->create());
        $fixture = Fixture::factory()->create(); // scheduled

        $this->postJson("/api/v1/fixtures/{$fixture->id}/predictions", ['home' => 2, 'away' => 1])
            ->assertOk()
            ->assertJsonPath('data.outcome', 'home');

        $this->getJson("/api/v1/fixtures/{$fixture->id}/predictions/summary")
            ->assertOk()
            ->assertJsonPath('data.total', 1)
            ->assertJsonPath('data.home_percent', 100)
            ->assertJsonPath('data.is_open', true)
            ->assertJsonPath('data.my_prediction.home', 2);

        $this->assertSame(1, $fixture->fresh()->predict_home_count);
    }

    public function test_updating_a_prediction_moves_the_aggregate_counters(): void
    {
        Sanctum::actingAs(User::factory()->create());
        $fixture = Fixture::factory()->create();

        $this->postJson("/api/v1/fixtures/{$fixture->id}/predictions", ['home' => 2, 'away' => 1])->assertOk();
        $this->postJson("/api/v1/fixtures/{$fixture->id}/predictions", ['home' => 0, 'away' => 2])->assertOk();

        $fixture->refresh();
        $this->assertSame(0, $fixture->predict_home_count);
        $this->assertSame(1, $fixture->predict_away_count);
        $this->assertSame(1, $fixture->predictions_count);
    }

    public function test_prediction_is_rejected_after_kickoff(): void
    {
        Sanctum::actingAs(User::factory()->create());
        $fixture = Fixture::factory()->live()->create();

        $this->postJson("/api/v1/fixtures/{$fixture->id}/predictions", ['home' => 1, 'away' => 0])
            ->assertStatus(422);
    }

    public function test_correct_predictions_are_listed_oldest_first_after_settlement(): void
    {
        $fixture = Fixture::factory()->create();

        // Three predictions; two pick a home win, one picks away.
        $first = $this->prediction($fixture, 2, 0);   // home — correct
        $this->prediction($fixture, 0, 1);             // away — wrong
        $second = $this->prediction($fixture, 1, 0);  // home — correct

        $fixture->update([
            'status_short' => 'FT',
            'status_group' => 'finished',
            'home_goals' => 3,
            'away_goals' => 1,
            'winner' => 'home',
        ]);

        (new SettleFixturePredictionsJob($fixture->id))->handle();

        Sanctum::actingAs(User::factory()->create());

        $response = $this->getJson("/api/v1/fixtures/{$fixture->id}/predictions/correct")
            ->assertOk()
            ->assertJsonCount(2, 'data');

        // Oldest-first ordering.
        $this->assertSame($first->id, $response->json('data.0.id'));
        $this->assertSame($second->id, $response->json('data.1.id'));
    }

    private function prediction(Fixture $fixture, int $home, int $away): FixturePrediction
    {
        return FixturePrediction::create([
            'fixture_id' => $fixture->id,
            'user_id' => User::factory()->create()->id,
            'predicted_home_score' => $home,
            'predicted_away_score' => $away,
            'predicted_outcome' => PredictionOutcome::fromScores($home, $away),
        ]);
    }
}
