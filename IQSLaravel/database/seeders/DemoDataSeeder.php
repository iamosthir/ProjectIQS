<?php

namespace Database\Seeders;

use App\Models\AppNotification;
use App\Models\Banner;
use App\Models\Club;
use App\Models\ClubBoardMember;
use App\Models\ClubNews;
use App\Models\ClubVerification;
use App\Models\Comment;
use App\Models\DeviceToken;
use App\Models\FanGroup;
use App\Models\FanGroupChant;
use App\Models\FanGroupMedia;
use App\Models\FanGroupVerification;
use App\Models\Fixture;
use App\Models\League;
use App\Models\Listing;
use App\Models\MarketplaceCategory;
use App\Models\NotificationBatch;
use App\Models\Payment;
use App\Models\Player;
use App\Models\Season;
use App\Models\Standing;
use App\Models\Store;
use App\Models\Team;
use App\Models\TopScorer;
use App\Models\User;
use App\Models\Venue;
use App\Support\Enums\BannerPlacement;
use App\Support\Enums\LeagueCategory;
use App\Support\Enums\ListingStatus;
use App\Support\Enums\NotificationBatchStatus;
use App\Support\Enums\StoreStatus;
use Illuminate\Database\Seeder;

/**
 * Generates a realistic demo dataset so the Flutter app and the full admin
 * panel can be exercised end-to-end. Idempotent: skips if the demo user
 * already exists. Never intended for production data.
 */
class DemoDataSeeder extends Seeder
{
    private const DEMO_PHONE = '+9647700000001';

    public function run(): void
    {
        if (app()->isProduction()) {
            $this->command?->warn('DemoDataSeeder skipped in production.');

            return;
        }

        if (User::where('phone', self::DEMO_PHONE)->exists()) {
            $this->command?->info('Demo data already present — skipping.');

            return;
        }

        [$demo, $seller, $clubAdmin, $groupAdmin, $crowd] = $this->seedUsers();
        $this->seedMatchModule($demo, $crowd);
        $this->seedMarketplace($seller, $crowd);
        $this->seedClubs($clubAdmin, $crowd);
        $this->seedFanGroups($groupAdmin, $crowd);
        $this->seedPayments($demo, $crowd);
        $this->seedNotifications($demo, $crowd);
        $this->seedBanners();
        $this->seedAppVersions();

        $this->command?->info('Demo data seeded. Flutter login phone: '.self::DEMO_PHONE);
    }

    /**
     * @return array{0: User, 1: User, 2: User, 3: User, 4: \Illuminate\Support\Collection<int, User>}
     */
    private function seedUsers(): array
    {
        $demo = User::factory()->create([
            'phone' => self::DEMO_PHONE,
            'name' => 'Demo User',
            'governorate' => 'Baghdad',
        ]);

        $seller = User::factory()->create(['phone' => '+9647700000002', 'name' => 'Demo Seller']);
        $seller->assignRole('seller');

        $clubAdmin = User::factory()->create(['phone' => '+9647700000003', 'name' => 'Demo Club Admin']);
        $clubAdmin->assignRole('club-admin');

        $groupAdmin = User::factory()->create(['phone' => '+9647700000004', 'name' => 'Demo Group Admin']);
        $groupAdmin->assignRole('group-admin');

        $crowd = User::factory()->count(20)->create();

        return [$demo, $seller, $clubAdmin, $groupAdmin, $crowd];
    }

    /**
     * @param  \Illuminate\Support\Collection<int, User>  $crowd
     */
    private function seedMatchModule(User $demo, $crowd): void
    {
        $league = League::where('category', LeagueCategory::Premier->value)->first()
            ?? League::factory()->create(['name_en' => 'Iraqi Premier League']);

        $season = Season::factory()->create(['league_id' => $league->id, 'is_current' => true]);
        $venue = Venue::factory()->create();

        $teams = Team::factory()->count(12)->create();

        // Squad of players for the first two teams (team detail / squad screens).
        foreach ($teams->take(2) as $team) {
            $players = Player::factory()->count(16)->create();
            foreach ($players as $i => $player) {
                $team->players()->attach($player->id, [
                    'season_id' => $season->id,
                    'number' => $i + 1,
                    'position' => $player->position,
                    'is_active' => true,
                ]);
            }
        }

        // League table.
        foreach ($teams->values() as $rank => $team) {
            Standing::factory()->create([
                'league_id' => $league->id,
                'season_id' => $season->id,
                'team_id' => $team->id,
                'rank' => $rank + 1,
                'display_order' => $rank + 1,
            ]);
        }

        // Top scorers.
        TopScorer::factory()->count(8)->create(['league_id' => $league->id]);

        $base = ['league_id' => $league->id, 'season_id' => $season->id, 'venue_id' => $venue->id];

        // Finished, live and upcoming fixtures.
        $finished = collect();
        foreach ($this->pairs($teams, 5) as $pair) {
            $finished->push(Fixture::factory()->finished(rand(0, 3), rand(0, 2))->create($base + [
                'home_team_id' => $pair[0]->id,
                'away_team_id' => $pair[1]->id,
            ]));
        }

        $live = $this->pairs($teams, 1)->map(fn ($pair) => Fixture::factory()->live(2, 1)->create($base + [
            'home_team_id' => $pair[0]->id,
            'away_team_id' => $pair[1]->id,
            'is_featured' => true,
        ]));

        $upcoming = collect();
        foreach ($this->pairs($teams, 5) as $pair) {
            $upcoming->push(Fixture::factory()->create($base + [
                'home_team_id' => $pair[0]->id,
                'away_team_id' => $pair[1]->id,
            ]));
        }

        // Social signals on a couple of fixtures.
        $hot = $upcoming->first();
        if ($hot !== null) {
            foreach ($crowd->take(8) as $user) {
                \App\Models\FixturePrediction::factory()->create([
                    'fixture_id' => $hot->id,
                    'user_id' => $user->id,
                ]);
            }
            Comment::factory()->count(5)->create([
                'commentable_type' => (new Fixture)->getMorphClass(),
                'commentable_id' => $hot->id,
            ]);
            Comment::factory()->create([
                'commentable_type' => (new Fixture)->getMorphClass(),
                'commentable_id' => $hot->id,
                'user_id' => $demo->id,
                'body' => 'Demo comment from the seed user.',
            ]);
        }

        // Fixture news on the live + first finished match (the News tab).
        collect([$live->first(), $finished->first()])
            ->filter()
            ->each(fn (Fixture $fixture) => \App\Models\FixtureNews::factory()
                ->count(3)
                ->create(['fixture_id' => $fixture->id]));
    }

    /**
     * @param  \Illuminate\Support\Collection<int, User>  $crowd
     */
    private function seedMarketplace(User $seller, $crowd): void
    {
        $categories = MarketplaceCategory::query()->whereNotNull('parent_id')->get();
        if ($categories->isEmpty()) {
            $categories = MarketplaceCategory::query()->get();
        }
        $pick = fn () => $categories->isNotEmpty() ? $categories->random()->id : MarketplaceCategory::factory()->create()->id;

        $sellerStore = Store::factory()->create([
            'user_id' => $seller->id,
            'name_en' => 'Demo Sports Store',
            'status' => StoreStatus::Active,
        ]);

        // Seller's published + pending listings.
        Listing::factory()->count(4)->published()->create([
            'store_id' => $sellerStore->id,
            'user_id' => $seller->id,
            'category_id' => $pick(),
        ]);
        Listing::factory()->count(2)->status(ListingStatus::PendingReview)->create([
            'store_id' => $sellerStore->id,
            'user_id' => $seller->id,
            'category_id' => $pick(),
        ]);

        // A pending store awaiting verification (admin queue).
        Store::factory()->pending()->create(['name_en' => 'Pending Store']);

        // Listings from the wider crowd in various states.
        foreach ($crowd->take(6) as $user) {
            $store = Store::factory()->create(['user_id' => $user->id]);
            Listing::factory()->published()->create([
                'store_id' => $store->id, 'user_id' => $user->id, 'category_id' => $pick(),
            ]);
        }
        Listing::factory()->count(3)->status(ListingStatus::PendingReview)->create([
            'category_id' => $pick(),
        ]);
        Listing::factory()->count(2)->status(ListingStatus::Rejected)->create([
            'category_id' => $pick(),
            'rejection_reason' => 'Incomplete information.',
        ]);
    }

    /**
     * @param  \Illuminate\Support\Collection<int, User>  $crowd
     */
    private function seedClubs(User $clubAdmin, $crowd): void
    {
        $managed = Club::factory()->verified()->managedBy($clubAdmin)->create([
            'name_en' => 'Demo Athletic Club',
            'name_ar' => 'نادي العرض الرياضي',
        ]);
        ClubNews::factory()->count(4)->create(['club_id' => $managed->id]);
        ClubBoardMember::factory()->count(5)->create(['club_id' => $managed->id]);

        $others = Club::factory()->count(5)->create();
        $others->take(2)->each(fn (Club $c) => $c->update(['is_verified' => true, 'verified_at' => now()]));
        foreach ($others as $club) {
            ClubNews::factory()->count(2)->create(['club_id' => $club->id]);
        }

        // Pending verification request for the admin queue.
        ClubVerification::factory()->create([
            'club_id' => $others->first()->id,
            'requested_by' => $crowd->first()->id,
            'verifiable_id' => $crowd->first()->id,
        ]);
    }

    /**
     * @param  \Illuminate\Support\Collection<int, User>  $crowd
     */
    private function seedFanGroups(User $groupAdmin, $crowd): void
    {
        $managed = FanGroup::factory()->verified()->managedBy($groupAdmin)->create([
            'name_en' => 'Demo Ultras',
            'name_ar' => 'رابطة العرض',
        ]);
        FanGroupChant::factory()->count(4)->create(['fan_group_id' => $managed->id]);
        FanGroupMedia::factory()->count(6)->create(['fan_group_id' => $managed->id]);
        FanGroupMedia::factory()->count(2)->video()->create(['fan_group_id' => $managed->id]);

        $others = FanGroup::factory()->count(4)->create();
        foreach ($others as $group) {
            FanGroupChant::factory()->count(2)->create(['fan_group_id' => $group->id]);
            FanGroupMedia::factory()->count(3)->create(['fan_group_id' => $group->id]);
        }

        FanGroupVerification::factory()->create([
            'fan_group_id' => $others->first()->id,
            'user_id' => $crowd->first()->id,
        ]);
    }

    /**
     * @param  \Illuminate\Support\Collection<int, User>  $crowd
     */
    private function seedPayments(User $demo, $crowd): void
    {
        Payment::factory()->paid()->create([
            'user_id' => $demo->id,
            'payable_type' => (new User)->getMorphClass(),
            'payable_id' => $demo->id,
        ]);

        foreach ($crowd->take(5) as $user) {
            Payment::factory()->paid()->create([
                'user_id' => $user->id,
                'payable_type' => (new User)->getMorphClass(),
                'payable_id' => $user->id,
            ]);
        }
        Payment::factory()->count(3)->create([
            'payable_type' => (new User)->getMorphClass(),
            'payable_id' => $crowd->random()->id,
        ]);
    }

    /**
     * @param  \Illuminate\Support\Collection<int, User>  $crowd
     */
    private function seedNotifications(User $demo, $crowd): void
    {
        DeviceToken::factory()->create(['user_id' => $demo->id, 'token' => 'demo-android-token']);

        NotificationBatch::factory()->create([
            'title_en' => 'Welcome to IQS',
            'title_ar' => 'مرحباً بك في IQS',
            'status' => NotificationBatchStatus::Sent,
            'total_recipients' => $crowd->count() + 1,
        ]);

        AppNotification::factory()->count(3)->for($demo)->create();
        AppNotification::factory()->count(2)->for($demo)->read()->create();

        foreach ($crowd->take(8) as $user) {
            AppNotification::factory()->for($user)->create();
        }
    }

    private function seedBanners(): void
    {
        Banner::factory()->create([
            'title_en' => 'Premier League is live', 'title_ar' => 'الدوري الممتاز مباشر',
            'placement' => BannerPlacement::HomeTop, 'position' => 1,
        ]);
        Banner::factory()->create([
            'title_en' => 'Follow your club', 'title_ar' => 'تابع ناديك',
            'placement' => BannerPlacement::HomeMiddle, 'position' => 1,
        ]);
        Banner::factory()->create([
            'title_en' => 'Marketplace deals', 'title_ar' => 'عروض السوق',
            'placement' => BannerPlacement::MarketplaceTop, 'position' => 1,
        ]);
    }

    private function seedAppVersions(): void
    {
        \App\Models\AppVersion::create([
            'platform' => 'android', 'version' => '1.2.0', 'build_number' => 12,
            'min_supported_version' => '1.0.0', 'is_force_update' => false,
            'store_url' => 'https://play.google.com/store/apps/details?id=iq.iqs',
            'changelog_ar' => 'تحسينات وإصلاحات.', 'changelog_en' => 'Improvements and fixes.',
            'is_active' => true, 'released_at' => now()->subWeek(),
        ]);
        \App\Models\AppVersion::create([
            'platform' => 'ios', 'version' => '1.2.0', 'build_number' => 12,
            'min_supported_version' => '1.0.0', 'is_force_update' => false,
            'store_url' => 'https://apps.apple.com/app/id000000000',
            'changelog_ar' => 'تحسينات وإصلاحات.', 'changelog_en' => 'Improvements and fixes.',
            'is_active' => true, 'released_at' => now()->subWeek(),
        ]);
    }

    /**
     * Build N non-overlapping (home, away) team pairs from the collection.
     *
     * @param  \Illuminate\Support\Collection<int, Team>  $teams
     * @return \Illuminate\Support\Collection<int, array{0: Team, 1: Team}>
     */
    private function pairs($teams, int $count)
    {
        $pairs = collect();
        for ($i = 0; $i < $count; $i++) {
            $two = $teams->random(2)->values();
            $pairs->push([$two[0], $two[1]]);
        }

        return $pairs;
    }
}
