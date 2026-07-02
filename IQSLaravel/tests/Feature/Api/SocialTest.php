<?php

namespace Tests\Feature\Api;

use App\Models\Comment;
use App\Models\Fixture;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SocialTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Sanctum::actingAs(User::factory()->create());
    }

    public function test_commenting_increments_the_fixture_counter(): void
    {
        $fixture = Fixture::factory()->create();

        $this->postJson("/api/v1/fixtures/{$fixture->id}/comments", ['body' => 'يلا القوة الجوية', 'context' => 'match'])
            ->assertCreated()
            ->assertJsonPath('data.body', 'يلا القوة الجوية');

        $this->assertSame(1, $fixture->fresh()->comments_count);

        $this->getJson("/api/v1/fixtures/{$fixture->id}/comments")
            ->assertOk()
            ->assertJsonCount(1, 'data');
    }

    public function test_replies_increment_the_parent_counter(): void
    {
        $fixture = Fixture::factory()->create();
        $parent = Comment::factory()->create([
            'commentable_id' => $fixture->id,
            'commentable_type' => $fixture->getMorphClass(),
        ]);

        $this->postJson("/api/v1/fixtures/{$fixture->id}/comments", [
            'body' => 'رد',
            'parent_id' => $parent->id,
        ])->assertCreated();

        $this->assertSame(1, $parent->fresh()->replies_count);

        $this->getJson("/api/v1/comments/{$parent->id}/replies")
            ->assertOk()
            ->assertJsonCount(1, 'data');
    }

    public function test_liking_a_fixture_is_idempotent_and_toggles(): void
    {
        $fixture = Fixture::factory()->create();

        $this->postJson("/api/v1/fixtures/{$fixture->id}/like")->assertOk()->assertJsonPath('data.likes_count', 1);
        // Liking again must not double-count.
        $this->postJson("/api/v1/fixtures/{$fixture->id}/like")->assertOk()->assertJsonPath('data.likes_count', 1);
        $this->deleteJson("/api/v1/fixtures/{$fixture->id}/like")->assertOk()->assertJsonPath('data.likes_count', 0);
    }

    public function test_sharing_increments_the_counter(): void
    {
        $fixture = Fixture::factory()->create();

        $this->postJson("/api/v1/fixtures/{$fixture->id}/share")
            ->assertOk()
            ->assertJsonPath('data.shares_count', 1);
    }

    public function test_a_user_can_only_edit_their_own_comment(): void
    {
        $fixture = Fixture::factory()->create();
        $someoneElse = Comment::factory()->create([
            'commentable_id' => $fixture->id,
            'commentable_type' => $fixture->getMorphClass(),
        ]);

        $this->putJson("/api/v1/comments/{$someoneElse->id}", ['body' => 'hacked'])
            ->assertStatus(403);
    }
}
