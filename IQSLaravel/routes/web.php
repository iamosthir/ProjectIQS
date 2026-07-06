<?php

use App\Http\Controllers\Admin\AdminController;
use App\Http\Controllers\Admin\AppVersionController;
use App\Http\Controllers\Admin\Auth\AuthController;
use App\Http\Controllers\Admin\BannerController as AdminBannerController;
use App\Http\Controllers\Admin\Clubs\ClubController as AdminClubController;
use App\Http\Controllers\Admin\Clubs\VerificationController as ClubVerificationController;
use App\Http\Controllers\Admin\FanGroups\FanGroupController as AdminFanGroupController;
use App\Http\Controllers\Admin\FanGroups\VerificationController as FanGroupVerificationController;
use App\Http\Controllers\Admin\Marketplace\CategoryController as MarketCategoryController;
use App\Http\Controllers\Admin\Marketplace\ListingController as MarketListingController;
use App\Http\Controllers\Admin\Marketplace\StoreController as MarketStoreController;
use App\Http\Controllers\Admin\Matches\BroadcastController;
use App\Http\Controllers\Admin\Matches\CoachController as AdminCoachController;
use App\Http\Controllers\Admin\Matches\CommentModerationController;
use App\Http\Controllers\Admin\Matches\CountryController as AdminCountryController;
use App\Http\Controllers\Admin\Matches\EventController;
use App\Http\Controllers\Admin\Matches\FixtureController as AdminFixtureController;
use App\Http\Controllers\Admin\Matches\FixtureNewsController;
use App\Http\Controllers\Admin\Matches\FixturePlayerStatisticController;
use App\Http\Controllers\Admin\Matches\FixtureStatisticController;
use App\Http\Controllers\Admin\Matches\ForecastController;
use App\Http\Controllers\Admin\Matches\InjuryController as AdminInjuryController;
use App\Http\Controllers\Admin\Matches\LeagueController as AdminLeagueController;
use App\Http\Controllers\Admin\Matches\LineupController;
use App\Http\Controllers\Admin\Matches\PlayerController as AdminPlayerController;
use App\Http\Controllers\Admin\Matches\PlayerStatisticController;
use App\Http\Controllers\Admin\Matches\PredictionOversightController;
use App\Http\Controllers\Admin\Matches\SeasonController;
use App\Http\Controllers\Admin\Matches\SidelinedController as AdminSidelinedController;
use App\Http\Controllers\Admin\Matches\StandingController;
use App\Http\Controllers\Admin\Matches\SyncController;
use App\Http\Controllers\Admin\Matches\TeamController as AdminTeamController;
use App\Http\Controllers\Admin\Matches\TopScorerController;
use App\Http\Controllers\Admin\Matches\TransferController as AdminTransferController;
use App\Http\Controllers\Admin\Matches\TrophyController as AdminTrophyController;
use App\Http\Controllers\Admin\Matches\VenueController;
use App\Http\Controllers\Admin\NotificationController as AdminNotificationController;
use App\Http\Controllers\Admin\PageController as AdminPageController;
use App\Http\Controllers\Admin\PaymentController;
use App\Http\Controllers\Admin\RoleController;
use App\Http\Controllers\Admin\SettingController;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

/*
|--------------------------------------------------------------------------
| Storage symlink
|--------------------------------------------------------------------------
| Creates the public/storage -> storage/app/public symlink for hosts where
| `php artisan storage:link` cannot be run from the shell. Safe to hit more
| than once; reports if the link already exists.
*/
Route::get('/storage-link', function () {
    if (file_exists(public_path('storage'))) {
        return 'Storage link already exists.';
    }

    Artisan::call('storage:link');

    return Artisan::output() ?: 'Storage link created.';
});

/*
|--------------------------------------------------------------------------
| Admin JSON API — /admin/api/v1/*
|--------------------------------------------------------------------------
| Consumed by the Vue admin SPA. Session/cookie auth (web guard) with CSRF
| via the standard web middleware group. Defined BEFORE the SPA shell so the
| (?!api) fallback never swallows these endpoints. (§0.4 / §9.x)
*/
Route::prefix('admin/api/v1')->name('admin.api.')->group(function (): void {
    // Public within the prefix — establishes the session.
    Route::post('login', [AuthController::class, 'login'])->name('login');

    Route::middleware('auth:web')->group(function (): void {
        Route::post('logout', [AuthController::class, 'logout'])->name('logout');
        Route::get('me', [AuthController::class, 'me'])->name('me');

        // Admin user management
        Route::middleware('permission:manage admins')->group(function (): void {
            Route::apiResource('admins', AdminController::class);
        });

        // Role & permission management
        Route::middleware('permission:manage roles')->group(function (): void {
            Route::get('permissions', [RoleController::class, 'permissions'])->name('permissions.index');
            Route::apiResource('roles', RoleController::class);
        });

        // Settings, app versions & static pages
        Route::middleware('permission:manage settings')->group(function (): void {
            Route::apiResource('settings', SettingController::class)->except(['show']);
            Route::apiResource('app-versions', AppVersionController::class)
                ->parameters(['app-versions' => 'appVersion']);
            Route::apiResource('pages', AdminPageController::class);
        });

        // Promotional banners (permission: manage banners)
        Route::middleware('permission:manage banners')->group(function (): void {
            Route::post('banners/upload', [AdminBannerController::class, 'upload']);
            Route::apiResource('banners', AdminBannerController::class);
        });

        /*
        |------------------------------------------------------------------
        | Match module — Phase 2 (permission: manage matches)
        |------------------------------------------------------------------
        */
        Route::middleware('permission:manage matches')->group(function (): void {
            Route::post('leagues/{league}/toggle-lock', [AdminLeagueController::class, 'toggleLock']);
            Route::post('teams/{team}/toggle-lock', [AdminTeamController::class, 'toggleLock']);
            Route::post('fixtures/{fixture}/toggle-lock', [AdminFixtureController::class, 'toggleLock']);

            Route::post('leagues/upload', [AdminLeagueController::class, 'upload']);
            Route::post('teams/upload', [AdminTeamController::class, 'upload']);
            Route::post('players/upload', [AdminPlayerController::class, 'upload']);
            Route::post('lineups/upload', [LineupController::class, 'uploadPhoto']);
            Route::post('fixture-news/upload', [FixtureNewsController::class, 'upload']);

            Route::apiResource('leagues', AdminLeagueController::class);
            Route::apiResource('seasons', SeasonController::class)->except(['show']);
            Route::apiResource('venues', VenueController::class);
            Route::apiResource('teams', AdminTeamController::class);
            Route::apiResource('players', AdminPlayerController::class);
            Route::apiResource('fixtures', AdminFixtureController::class);
            Route::apiResource('standings', StandingController::class)->except(['show']);

            // Fixture detail (manual match console)
            Route::get('fixtures/{fixture}/broadcasts', [BroadcastController::class, 'index']);
            Route::post('fixtures/{fixture}/broadcasts', [BroadcastController::class, 'store']);
            Route::put('fixtures/{fixture}/broadcasts/{broadcast}', [BroadcastController::class, 'update']);
            Route::delete('fixtures/{fixture}/broadcasts/{broadcast}', [BroadcastController::class, 'destroy']);

            Route::get('fixtures/{fixture}/lineups', [LineupController::class, 'index']);
            Route::post('fixtures/{fixture}/lineups', [LineupController::class, 'store']);
            Route::delete('fixtures/{fixture}/lineups/{lineup}', [LineupController::class, 'destroy']);

            Route::get('fixtures/{fixture}/events', [EventController::class, 'index']);
            Route::post('fixtures/{fixture}/events', [EventController::class, 'store']);
            Route::put('fixtures/{fixture}/events/{event}', [EventController::class, 'update']);
            Route::delete('fixtures/{fixture}/events/{event}', [EventController::class, 'destroy']);

            Route::get('fixtures/{fixture}/statistics', [FixtureStatisticController::class, 'index']);
            Route::post('fixtures/{fixture}/statistics', [FixtureStatisticController::class, 'store']);
            Route::delete('fixtures/{fixture}/statistics/{statistic}', [FixtureStatisticController::class, 'destroy']);

            Route::get('fixtures/{fixture}/news', [FixtureNewsController::class, 'index']);
            Route::post('fixtures/{fixture}/news', [FixtureNewsController::class, 'store']);
            Route::put('fixtures/{fixture}/news/{news}', [FixtureNewsController::class, 'update']);
            Route::delete('fixtures/{fixture}/news/{news}', [FixtureNewsController::class, 'destroy']);

            Route::get('fixtures/{fixture}/predictions', [PredictionOversightController::class, 'index']);

            // League top scorers (auto-rank)
            Route::get('leagues/{league}/top-scorers', [TopScorerController::class, 'index']);
            Route::post('leagues/{league}/top-scorers', [TopScorerController::class, 'store']);
            Route::put('leagues/{league}/top-scorers/{topScorer}', [TopScorerController::class, 'update']);
            Route::delete('leagues/{league}/top-scorers/{topScorer}', [TopScorerController::class, 'destroy']);

            // API-Football parity entities (manual entry mirrors the doc)
            Route::apiResource('countries', AdminCountryController::class);
            Route::apiResource('coaches', AdminCoachController::class);
            Route::get('coaches/{coach}/careers', [AdminCoachController::class, 'careers']);
            Route::post('coaches/{coach}/careers', [AdminCoachController::class, 'storeCareer']);
            Route::put('coaches/{coach}/careers/{career}', [AdminCoachController::class, 'updateCareer']);
            Route::delete('coaches/{coach}/careers/{career}', [AdminCoachController::class, 'destroyCareer']);
            Route::apiResource('injuries', AdminInjuryController::class);
            Route::apiResource('transfers', AdminTransferController::class);
            Route::apiResource('trophies', AdminTrophyController::class);
            Route::apiResource('sidelined', AdminSidelinedController::class);
            Route::apiResource('player-statistics', PlayerStatisticController::class);

            Route::get('fixtures/{fixture}/player-statistics', [FixturePlayerStatisticController::class, 'index']);
            Route::post('fixtures/{fixture}/player-statistics', [FixturePlayerStatisticController::class, 'store']);
            Route::put('fixtures/{fixture}/player-statistics/{statistic}', [FixturePlayerStatisticController::class, 'update']);
            Route::delete('fixtures/{fixture}/player-statistics/{statistic}', [FixturePlayerStatisticController::class, 'destroy']);

            Route::get('fixtures/{fixture}/forecast', [ForecastController::class, 'show']);
            Route::put('fixtures/{fixture}/forecast', [ForecastController::class, 'upsert']);
            Route::delete('fixtures/{fixture}/forecast', [ForecastController::class, 'destroy']);
        });

        /*
        |------------------------------------------------------------------
        | Sync console (permission: sync matches)
        |------------------------------------------------------------------
        */
        Route::middleware('permission:sync matches')->group(function (): void {
            Route::prefix('sync')->group(function (): void {
                Route::post('leagues', [SyncController::class, 'leagues']);
                Route::post('teams', [SyncController::class, 'teams']);
                Route::post('standings', [SyncController::class, 'standings']);
                Route::post('fixtures', [SyncController::class, 'fixtures']);
                Route::post('top-scorers', [SyncController::class, 'topScorers']);
                Route::get('logs', [SyncController::class, 'logs']);

                // Automatic sync subscriptions (seasons.auto_sync)
                Route::get('auto', [SyncController::class, 'autoStatus']);
                Route::post('auto/seasons/{season}', [SyncController::class, 'toggleAuto']);
            });
            Route::post('fixtures/{fixture}/sync-details', [SyncController::class, 'fixtureDetails']);
        });

        /*
        |------------------------------------------------------------------
        | Comment moderation (permission: moderate comments)
        |------------------------------------------------------------------
        */
        Route::middleware('permission:moderate comments')->group(function (): void {
            Route::get('comments', [CommentModerationController::class, 'index']);
            Route::post('comments/{comment}/hide', [CommentModerationController::class, 'hide']);
            Route::delete('comments/{comment}', [CommentModerationController::class, 'destroy']);
        });

        /*
        |------------------------------------------------------------------
        | Payments — Phase 6 (permission: manage payments)
        |------------------------------------------------------------------
        */
        Route::middleware('permission:manage payments')->group(function (): void {
            Route::get('payments', [PaymentController::class, 'index']);
            Route::get('payments/webhooks', [PaymentController::class, 'webhooks']);
            Route::get('payments/{payment}', [PaymentController::class, 'show']);
            Route::post('payments/{payment}/refund', [PaymentController::class, 'refund']);
        });

        /*
        |------------------------------------------------------------------
        | Marketplace — Phase 3
        |------------------------------------------------------------------
        */
        Route::prefix('marketplace')->group(function (): void {
            // Categories, stores, leakage report (permission: manage marketplace)
            Route::middleware('permission:manage marketplace')->group(function (): void {
                Route::post('categories/upload', [MarketCategoryController::class, 'upload']);
                Route::apiResource('categories', MarketCategoryController::class);
                Route::get('stores', [MarketStoreController::class, 'index']);
                Route::get('stores/{store}', [MarketStoreController::class, 'show']);
                Route::post('stores/{store}/verify', [MarketStoreController::class, 'verify']);
                Route::post('stores/{store}/suspend', [MarketStoreController::class, 'suspend']);
                Route::post('stores/{store}/activate', [MarketStoreController::class, 'activate']);
                Route::get('contacts/report', [MarketListingController::class, 'contactsReport']);
            });

            // Listing review queue (permission: approve listings)
            Route::middleware('permission:approve listings')->group(function (): void {
                Route::get('listings', [MarketListingController::class, 'index']);
                Route::get('listings/{listing}', [MarketListingController::class, 'show']);
                Route::post('listings/{listing}/approve', [MarketListingController::class, 'approve']);
                Route::post('listings/{listing}/reject', [MarketListingController::class, 'reject']);
                Route::post('listings/{listing}/feature', [MarketListingController::class, 'feature']);
            });
        });

        /*
        |------------------------------------------------------------------
        | Clubs — Phase 4 (permission: manage clubs)
        |------------------------------------------------------------------
        */
        Route::middleware('permission:manage clubs')->group(function (): void {
            // Verification queue (static paths before clubs/{club})
            Route::get('clubs/verifications', [ClubVerificationController::class, 'index']);
            Route::post('clubs/verifications/{verification}/approve', [ClubVerificationController::class, 'approve']);
            Route::post('clubs/verifications/{verification}/reject', [ClubVerificationController::class, 'reject']);

            Route::post('clubs/{club}/verify', [AdminClubController::class, 'verify']);

            // Nested content
            Route::post('clubs/{club}/news', [AdminClubController::class, 'storeNews']);
            Route::put('clubs/{club}/news/{news}', [AdminClubController::class, 'updateNews']);
            Route::delete('clubs/{club}/news/{news}', [AdminClubController::class, 'destroyNews']);
            Route::post('clubs/{club}/content/{type}', [AdminClubController::class, 'storeChild']);
            Route::put('clubs/{club}/content/{type}/{id}', [AdminClubController::class, 'updateChild']);
            Route::delete('clubs/{club}/content/{type}/{id}', [AdminClubController::class, 'destroyChild']);

            Route::post('clubs/upload', [AdminClubController::class, 'upload']);

            Route::apiResource('clubs', AdminClubController::class);
        });

        /*
        |------------------------------------------------------------------
        | Fan Groups — Phase 5 (permission: manage fan-groups)
        |------------------------------------------------------------------
        */
        Route::middleware('permission:manage fan-groups')->group(function (): void {
            Route::get('fan-groups/verifications', [FanGroupVerificationController::class, 'index']);
            Route::post('fan-groups/verifications/{verification}/approve', [FanGroupVerificationController::class, 'approve']);
            Route::post('fan-groups/verifications/{verification}/reject', [FanGroupVerificationController::class, 'reject']);

            Route::post('fan-groups/{fanGroup}/verify', [AdminFanGroupController::class, 'verify']);

            // Archives
            Route::post('fan-groups/{fanGroup}/media', [AdminFanGroupController::class, 'storeMedia']);
            Route::delete('fan-groups/{fanGroup}/media/{media}', [AdminFanGroupController::class, 'destroyMedia']);
            Route::post('fan-groups/{fanGroup}/chants', [AdminFanGroupController::class, 'storeChant']);
            Route::delete('fan-groups/{fanGroup}/chants/{chant}', [AdminFanGroupController::class, 'destroyChant']);
            Route::post('fan-groups/{fanGroup}/documents', [AdminFanGroupController::class, 'storeDocument']);
            Route::delete('fan-groups/{fanGroup}/documents/{document}', [AdminFanGroupController::class, 'destroyDocument']);

            Route::post('fan-groups/upload', [AdminFanGroupController::class, 'upload']);

            Route::apiResource('fan-groups', AdminFanGroupController::class)->parameters(['fan-groups' => 'fanGroup']);
        });

        /*
        |------------------------------------------------------------------
        | Notifications — Phase 7 (permission: send notifications)
        |------------------------------------------------------------------
        */
        Route::prefix('notifications')->middleware('permission:send notifications')->group(function (): void {
            Route::get('compose', [AdminNotificationController::class, 'compose']);
            Route::post('send', [AdminNotificationController::class, 'send']);
            Route::get('batches', [AdminNotificationController::class, 'batches']);
            Route::get('batches/{batch}', [AdminNotificationController::class, 'batch']);
        });
    });
});

/*
|--------------------------------------------------------------------------
| Admin SPA shell
|--------------------------------------------------------------------------
| Serves the Vue 3 admin panel for every browser-facing /admin/* path so
| Vue Router (history mode, base "/admin") can deep-link and refresh. The
| (?!api) constraint keeps the /admin/api/v1/* JSON routes above intact.
*/
Route::view('/admin/{any?}', 'admin')->where('any', '^(?!api).*$');
