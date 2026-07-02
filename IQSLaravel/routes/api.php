<?php

use App\Http\Controllers\Api\V1\AppConfigController;
use App\Http\Controllers\Api\V1\Auth\AuthController;
use App\Http\Controllers\Api\V1\BannerController;
use App\Http\Controllers\Api\V1\ClubController;
use App\Http\Controllers\Api\V1\CommentController;
use App\Http\Controllers\Api\V1\DeviceController;
use App\Http\Controllers\Api\V1\FanGroupController;
use App\Http\Controllers\Api\V1\FixtureController;
use App\Http\Controllers\Api\V1\LeagueController;
use App\Http\Controllers\Api\V1\MarketplaceController;
use App\Http\Controllers\Api\V1\MyClubController;
use App\Http\Controllers\Api\V1\MyFanGroupController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Controllers\Api\V1\PageController;
use App\Http\Controllers\Api\V1\PaymentCallbackController;
use App\Http\Controllers\Api\V1\PaymentController;
use App\Http\Controllers\Api\V1\PlayerController;
use App\Http\Controllers\Api\V1\PredictionController;
use App\Http\Controllers\Api\V1\SearchController;
use App\Http\Controllers\Api\V1\TeamController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Mobile API (Flutter only) — /api/v1/*
|--------------------------------------------------------------------------
| Token auth via Sanctum (`auth:sanctum`, `users` provider). This file is
| consumed ONLY by the Flutter app. Admin endpoints live in web.php and are
| never mixed in here. Every response uses the standard envelope (§0.5).
*/

Route::prefix('v1')->group(function (): void {

    /*
    |----------------------------------------------------------------------
    | App config & static content — Phase 8 (public, no auth)
    |----------------------------------------------------------------------
    */
    Route::get('app/config', [AppConfigController::class, 'config']);
    Route::get('governorates', [AppConfigController::class, 'governorates']);
    Route::get('pages/{slug}', [PageController::class, 'show']);

    /*
    |----------------------------------------------------------------------
    | Auth (OTP) — Phase 1
    |----------------------------------------------------------------------
    */
    Route::prefix('auth')->group(function (): void {
        Route::post('request-otp', [AuthController::class, 'requestOtp'])
            ->middleware('throttle:6,1');
        Route::post('verify-otp', [AuthController::class, 'verifyOtp'])
            ->middleware('throttle:10,1');

        Route::middleware('auth:sanctum')->group(function (): void {
            Route::post('register', [AuthController::class, 'register']);
            Route::get('me', [AuthController::class, 'me']);
            Route::put('profile', [AuthController::class, 'updateProfile']);
            Route::post('logout', [AuthController::class, 'logout']);
            Route::delete('account', [AuthController::class, 'deleteAccount']);
        });
    });

    /*
    |----------------------------------------------------------------------
    | Match Sections — Phase 2 (all require auth; throttle:60,1)
    |----------------------------------------------------------------------
    */
    Route::middleware(['auth:sanctum', 'throttle:60,1'])->group(function (): void {

        // Leagues
        Route::get('leagues', [LeagueController::class, 'index']);
        Route::get('leagues/{league}', [LeagueController::class, 'show']);
        Route::get('leagues/{league}/standings', [LeagueController::class, 'standings']);
        Route::get('leagues/{league}/fixtures', [LeagueController::class, 'fixtures']);
        Route::get('leagues/{league}/top-scorers', [LeagueController::class, 'topScorers']);

        // Fixtures (static routes before the {fixture} wildcard)
        Route::get('fixtures', [FixtureController::class, 'index']);
        Route::get('fixtures/live', [FixtureController::class, 'live']);
        Route::get('fixtures/{fixture}', [FixtureController::class, 'show']);
        Route::get('fixtures/{fixture}/events', [FixtureController::class, 'events']);
        Route::get('fixtures/{fixture}/lineups', [FixtureController::class, 'lineups']);
        Route::get('fixtures/{fixture}/statistics', [FixtureController::class, 'statistics']);
        Route::get('fixtures/{fixture}/broadcasts', [FixtureController::class, 'broadcasts']);
        Route::get('fixtures/{fixture}/news', [FixtureController::class, 'news']);
        Route::post('fixtures/{fixture}/like', [FixtureController::class, 'like']);
        Route::delete('fixtures/{fixture}/like', [FixtureController::class, 'unlike']);
        Route::post('fixtures/{fixture}/share', [FixtureController::class, 'share']);

        // Predictions
        Route::get('fixtures/{fixture}/predictions/summary', [PredictionController::class, 'summary']);
        Route::get('fixtures/{fixture}/predictions/correct', [PredictionController::class, 'correct']);
        Route::post('fixtures/{fixture}/predictions', [PredictionController::class, 'store']);
        Route::post('predictions/{prediction}/like', [PredictionController::class, 'like']);
        Route::delete('predictions/{prediction}/like', [PredictionController::class, 'unlike']);

        // Comments & social
        Route::get('fixtures/{fixture}/comments', [CommentController::class, 'index']);
        Route::post('fixtures/{fixture}/comments', [CommentController::class, 'store']);
        Route::get('comments/{comment}/replies', [CommentController::class, 'replies']);
        Route::put('comments/{comment}', [CommentController::class, 'update']);
        Route::delete('comments/{comment}', [CommentController::class, 'destroy']);
        Route::post('comments/{comment}/like', [CommentController::class, 'like']);
        Route::delete('comments/{comment}/like', [CommentController::class, 'unlike']);

        // Teams & players
        Route::get('teams/{team}', [TeamController::class, 'show']);
        Route::get('teams/{team}/fixtures', [TeamController::class, 'fixtures']);
        Route::get('teams/{team}/squad', [TeamController::class, 'squad']);
        Route::get('players/{player}', [PlayerController::class, 'show']);
    });

    /*
    |----------------------------------------------------------------------
    | Payments — Phase 6
    |----------------------------------------------------------------------
    */
    Route::middleware('auth:sanctum')->group(function (): void {
        Route::get('payments', [PaymentController::class, 'index']);
        Route::post('payments/initiate', [PaymentController::class, 'initiate']);
        Route::get('payments/{number}/status', [PaymentController::class, 'status']);
    });

    // Public, signature-verified gateway callbacks.
    Route::match(['get', 'post'], 'payments/zaincash/callback', [PaymentCallbackController::class, 'zaincash']);
    Route::match(['get', 'post'], 'payments/fib/callback', [PaymentCallbackController::class, 'fib']);

    /*
    |----------------------------------------------------------------------
    | Marketplace — Phase 3
    |----------------------------------------------------------------------
    */
    Route::middleware('auth:sanctum')->prefix('marketplace')->group(function (): void {
        Route::get('categories', [MarketplaceController::class, 'categories']);
        Route::get('my-store', [MarketplaceController::class, 'myStore']);
        Route::get('my-listings', [MarketplaceController::class, 'myListings']);
        Route::get('listings', [MarketplaceController::class, 'listings']);
        Route::get('listings/{listing}', [MarketplaceController::class, 'showListing']);
        Route::post('listings/{listing}/contact', [MarketplaceController::class, 'contact']);
        Route::post('listings/{listing}/media', [MarketplaceController::class, 'uploadMedia']);
        Route::post('listings', [MarketplaceController::class, 'createListing']);
        Route::put('listings/{listing}', [MarketplaceController::class, 'updateListing']);
        Route::delete('listings/{listing}', [MarketplaceController::class, 'deleteListing']);
        Route::post('stores', [MarketplaceController::class, 'createStore']);
        Route::put('stores/{store}', [MarketplaceController::class, 'updateStore']);
    });

    /*
    |----------------------------------------------------------------------
    | Clubs — Phase 4
    |----------------------------------------------------------------------
    */
    Route::middleware('auth:sanctum')->group(function (): void {
        // Club-admin management of their own club (static paths before clubs/{club}).
        Route::get('my-club', [MyClubController::class, 'show']);
        Route::put('my-club', [MyClubController::class, 'update']);
        Route::post('my-club/news', [MyClubController::class, 'storeNews']);
        Route::put('my-club/news/{news}', [MyClubController::class, 'updateNews']);
        Route::delete('my-club/news/{news}', [MyClubController::class, 'destroyNews']);
        Route::post('my-club/{type}', [MyClubController::class, 'storeChild']);
        Route::put('my-club/{type}/{id}', [MyClubController::class, 'updateChild']);
        Route::delete('my-club/{type}/{id}', [MyClubController::class, 'destroyChild']);

        // Public club pages
        Route::get('clubs', [ClubController::class, 'index']);
        Route::get('clubs/{club}', [ClubController::class, 'show']);
        Route::get('clubs/{club}/news', [ClubController::class, 'news']);
        Route::get('clubs/{club}/news/{news}', [ClubController::class, 'newsArticle']);
        Route::post('clubs/{club}/verify-request', [ClubController::class, 'verifyRequest']);
    });

    /*
    |----------------------------------------------------------------------
    | Fan Groups — Phase 5
    |----------------------------------------------------------------------
    */
    Route::middleware('auth:sanctum')->group(function (): void {
        // Group-admin management (static paths before fan-groups/{fanGroup}).
        Route::get('my-fan-group', [MyFanGroupController::class, 'show']);
        Route::put('my-fan-group', [MyFanGroupController::class, 'update']);
        Route::post('my-fan-group/media', [MyFanGroupController::class, 'storeMedia']);
        Route::delete('my-fan-group/media/{media}', [MyFanGroupController::class, 'destroyMedia']);
        Route::post('my-fan-group/chants', [MyFanGroupController::class, 'storeChant']);
        Route::delete('my-fan-group/chants/{chant}', [MyFanGroupController::class, 'destroyChant']);
        Route::post('my-fan-group/documents', [MyFanGroupController::class, 'storeDocument']);
        Route::delete('my-fan-group/documents/{document}', [MyFanGroupController::class, 'destroyDocument']);

        // Public fan group pages
        Route::get('fan-groups', [FanGroupController::class, 'index']);
        Route::get('fan-groups/{fanGroup}', [FanGroupController::class, 'show']);
        Route::get('fan-groups/{fanGroup}/media', [FanGroupController::class, 'media']);
        Route::get('fan-groups/{fanGroup}/chants', [FanGroupController::class, 'chants']);
        Route::post('fan-groups/{fanGroup}/verify-request', [FanGroupController::class, 'verifyRequest']);
    });

    /*
    |----------------------------------------------------------------------
    | Devices & Notifications — Phase 7
    |----------------------------------------------------------------------
    */
    Route::middleware('auth:sanctum')->group(function (): void {
        Route::post('devices/register', [DeviceController::class, 'register']);
        Route::delete('devices/unregister', [DeviceController::class, 'unregister']);

        Route::get('notifications', [NotificationController::class, 'index']);
        Route::get('notifications/unread-count', [NotificationController::class, 'unreadCount']);
        Route::post('notifications/read-all', [NotificationController::class, 'readAll']);
        Route::post('notifications/{notification}/read', [NotificationController::class, 'read']);
    });

    /*
    |----------------------------------------------------------------------
    | Banners & global search — Phase 8 (auth)
    |----------------------------------------------------------------------
    */
    Route::middleware('auth:sanctum')->group(function (): void {
        Route::get('banners', [BannerController::class, 'index']);
        Route::get('search', [SearchController::class, 'search']);
    });

});
