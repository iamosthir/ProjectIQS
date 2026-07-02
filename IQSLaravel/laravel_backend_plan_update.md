# IQS — Iraqi Sports Super-App · Laravel 12 Backend Plan

> Single Laravel 12 codebase serving **two fully separated surfaces**:
> 1. **Mobile API** (`routes/api.php`, prefix `/api/v1`) — consumed **only** by the Flutter app. Token auth (Sanctum).
> 2. **Admin Panel** — a standalone **Vue 3 SPA + Vue Router** (no Inertia) that consumes a **JSON admin API in `routes/web.php`** (`/admin/api/v1/*`), with the SPA shell served by one `/admin` fallback route. Session/cookie auth (`web` guard). Never touches `api.php`.
>
> This document is the execution spec for Claude Code agents. Work through it **phase by phase**. Each phase is self-contained: schema → models → services/jobs → endpoints → admin → policies → acceptance criteria.

---

## Table of Contents

- [0. Architecture & Conventions](#0-architecture--conventions)
- [1. Foundation (Auth, Roles, Core)](#phase-1--foundation)
- [2. Match Sections](#phase-2--match-sections)
- [3. Sports Marketplace](#phase-3--sports-marketplace)
- [4. Sports Clubs](#phase-4--sports-clubs)
- [5. Fan Groups](#phase-5--fan-groups)
- [6. Payments (ZainCash + FIB)](#phase-6--payments)
- [7. Notifications (FCM)](#phase-7--notifications)
- [8. App Config & Cross-Cutting](#phase-8--app-config--cross-cutting)
- [9. Admin Panel](#phase-9--admin-panel)
- [10. Execution Order for Claude Code](#10-execution-order-for-claude-code)

---

## 0. Architecture & Conventions

### 0.1 Tech Stack

| Layer | Choice |
|---|---|
| Framework | Laravel 12 (PHP 8.3+) |
| Database | MySQL 8 |
| Mobile API auth | Laravel Sanctum (personal access tokens) |
| Admin auth | Session/cookie (`web` guard) + CSRF, separate `admins` table |
| Roles/Permissions | `spatie/laravel-permission` (guard-aware) |
| Media | `spatie/laravel-medialibrary` (local disk) **or** custom `*_media` tables (this plan uses explicit media tables for per-entity limits) |
| Admin UI | **Standalone Vue 3 SPA + Vue Router (history mode) + Pinia + Vite + Tailwind (RTL). No Inertia.** Consumes the admin JSON API in `web.php`. |
| Queue | `database` driver (no Redis) |
| Cache | `database` or `file` (no Redis) |
| Push | FCM via `kreait/laravel-firebase` |
| HTTP client | Laravel `Http` facade (Guzzle) |
| Match data source | API-Football v3 + manual DB entry, merged into one canonical store |

### 0.2 Recommended Composer Packages

```
laravel/sanctum
spatie/laravel-permission
spatie/laravel-medialibrary
spatie/laravel-activitylog        # admin audit trail (optional but recommended)
spatie/laravel-query-builder      # clean filtering/sorting on API list endpoints
kreait/laravel-firebase           # FCM push
propaganistas/laravel-phone       # Iraqi phone validation/normalization
```

> **Admin SPA is a separate Vite/npm frontend, not a Composer package.** No Inertia, no Ziggy. NPM side: `vue`, `vue-router`, `pinia`, `axios`, `tailwindcss`, plus a component/UI kit of choice (e.g. PrimeVue / Element Plus / shadcn-vue). Built with Vite and served same-origin from Laravel (see Phase 9).

### 0.3 Directory Conventions

```
app/
  Models/
  Http/
    Controllers/
      Api/V1/            # mobile API controllers ONLY
      Admin/             # admin JSON controllers (for the Vue SPA) ONLY
    Requests/
      Api/
      Admin/
    Resources/           # API JSON Resources (the common output format)
    Middleware/
  Services/
    ApiFootball/         # external API client + sync
    Payment/             # ZainCash, FIB gateways
    Notification/        # FCM dispatch
  Jobs/                  # queued sync + push jobs
  Console/Commands/      # sync:* commands
  Support/
    Enums/               # PHP enums (FixtureStatus, PaymentStatus, etc.)
    DataTransferObjects/ # API-Football response DTOs
resources/
  js/
    admin/               # Vue 3 SPA: router, pinia stores, views, components (built by Vite)
  views/
    admin.blade.php      # SPA shell — mounts the built Vue admin bundle
routes/
  api.php                # /api/v1/* — Flutter ONLY (Sanctum tokens)
  web.php                # /admin/api/v1/* (JSON) + the /admin SPA shell route — admin ONLY
  console.php            # scheduled sync tasks
database/
  migrations/
  seeders/
```

### 0.4 Auth Separation (critical)

Two guards, two providers, two user tables. **No overlap.**

`config/auth.php`:
```php
'guards' => [
    'web'     => ['driver' => 'session', 'provider' => 'admins'], // admin panel
    'sanctum' => ['driver' => 'sanctum', 'provider' => 'users'],  // flutter app
],
'providers' => [
    'admins' => ['driver' => 'eloquent', 'model' => App\Models\Admin::class],
    'users'  => ['driver' => 'eloquent', 'model' => App\Models\User::class],
],
```

- **Admin** (Vue SPA): logs in via `POST /admin/api/v1/login` → `Auth::guard('web')->attempt()` → **session cookie** → `web` guard → `Admin` model. The SPA is served **same-origin** from Laravel, so CSRF protection works through the standard `web` middleware: Laravel sets an `XSRF-TOKEN` cookie and axios echoes it back as the `X-XSRF-TOKEN` header automatically. Protected admin endpoints use `auth:web`. (If you ever host the SPA on a *different* origin, switch to Sanctum stateful domains via `/sanctum/csrf-cookie`, or a dedicated admin token guard.)
- **App user** authenticates via OTP at `/api/v1/auth/*` → Sanctum token → `auth:sanctum` → `User` model (`HasApiTokens`).
- `spatie/laravel-permission` roles are guard-scoped: admin roles use `web`, app-user capability roles use `sanctum`. They live in the same tables but never collide because of `guard_name`.

**Admin routing convention (applies to every `/admin/...` block in this document).** The admin is a SPA, so the server exposes two things in `web.php`:
1. **JSON endpoints** under the `/admin/api/v1/*` prefix, returning JSON, protected by `auth:web` (+ permission middleware). **Read every `/admin/<resource>` line in Phases 1–8 as the JSON endpoint `/admin/api/v1/<resource>`.**
2. **One SPA-shell fallback route** — `GET /admin/{any?}` (where `any` excludes `api/...`) returns `admin.blade.php`. Vue Router (history mode, base `/admin`) owns all browser-facing `/admin/*` paths; refresh/deep-link on any of them loads the SPA.

### 0.5 Standard API Response Envelope

Every `/api/v1` response uses this shape. Build a `ApiResponse` helper / base controller trait.

**Success:**
```json
{
  "success": true,
  "message": "OK",
  "data": { },
  "meta": { "pagination": { "current_page": 1, "per_page": 20, "total": 134, "last_page": 7 } }
}
```

**Error:**
```json
{
  "success": false,
  "message": "The given data was invalid.",
  "errors": { "phone": ["The phone field is required."] }
}
```

- Validation errors → HTTP 422.
- Auth errors → 401. Authorization → 403. Not found → 404. Rate limit → 429. Server → 500.
- Register a single exception handler mapping for `api/*` so the app always gets the envelope (never an HTML error page).

### 0.6 Localization (Arabic-first, RTL)

- App sends `Accept-Language: ar` (default) or `en`.
- Translatable display fields stored as paired columns: `name_ar` + `name_en` (and `_ar`/`_en` for descriptions/titles).
- API Resources resolve the active locale, falling back to the other language if one is empty:
  `'name' => $this->name_ar ?: $this->name_en`
- API-Football data arrives in English → stored in `*_en`. Admin adds Arabic overrides in `*_ar`. App shows `name_ar` when present, else `name_en`.

### 0.7 API Conventions

- Versioned prefix: `/api/v1`.
- All list endpoints paginated (default 20, max 50) via `?page=` and `?per_page=`.
- Filtering/sorting via `spatie/laravel-query-builder` where useful.
- Throttling: `throttle:60,1` on authenticated routes; tighter (`throttle:6,1`) on OTP request.
- All app-facing routes that expose user data require `auth:sanctum`.
- Per client requirement: **league fixtures & standings require auth** — gate those endpoints behind `auth:sanctum` and the league's `requires_auth` flag.

### 0.8 Environment Variables

```env
# Mobile / app
APP_LOCALE=ar
APP_FALLBACK_LOCALE=en

# Queue & cache (no Redis)
QUEUE_CONNECTION=database
CACHE_STORE=database

# API-Football v3
API_FOOTBALL_KEY=
API_FOOTBALL_BASE_URL=https://v3.football.api-sports.io
API_FOOTBALL_HOST=v3.football.api-sports.io
API_FOOTBALL_TIMEZONE=Asia/Baghdad
API_FOOTBALL_DAILY_LIMIT=100          # match your plan; guard sync against this
API_FOOTBALL_LIVE_POLL_SECONDS=60     # live fixture refresh cadence

# FCM
FIREBASE_CREDENTIALS=storage/app/firebase/service-account.json
FCM_PROJECT_ID=

# ZainCash
ZAINCASH_MERCHANT_ID=
ZAINCASH_SECRET=
ZAINCASH_MSISDN=
ZAINCASH_BASE_URL=https://api.zaincash.iq        # use test URL in non-prod
ZAINCASH_REDIRECT_URL=

# FIB (First Iraqi Bank)
FIB_CLIENT_ID=
FIB_CLIENT_SECRET=
FIB_BASE_URL=https://fib.prod.fib.iq             # confirm with FIB onboarding docs
FIB_CALLBACK_URL=
```

### 0.9 The Common Match-Data Format (core design decision)

The client requires API-Football data **and** manually-entered data (lower divisions, youth, juniors that the API doesn't cover) to appear in one unified format. Do **not** merge at read-time — that is slow and fragile.

**Strategy: canonical local store. The database is the single source of truth. API-Football is synced *into* our schema. The Flutter app only ever reads from our DB, in our format.**

Every syncable entity (`leagues`, `teams`, `players`, `coaches`, `venues`, `fixtures`, `standings`, `fixture_events`, `fixture_lineups`, `fixture_statistics`) carries:

| Column | Purpose |
|---|---|
| `source` | enum `api_football` \| `manual` — origin of the row |
| `external_id` | API-Football's numeric ID (nullable; null for manual rows). Indexed. |
| `external_payload` | JSON — raw API response for that entity (debugging / re-sync) |
| `last_synced_at` | timestamp of last successful sync (null for manual rows) |

**Sync flow:** scheduled console commands → `ApiFootballService` (HTTP) → DTO transformers → **upsert** keyed on `(source = api_football, external_id)`. Manual rows (`source = manual`) are **never** overwritten by sync.

**Conflict handling:** an `is_locked` boolean on synced tables lets an admin pin a manual override on an otherwise-synced row (sync skips locked rows).

**Output:** Laravel JSON Resources (`FixtureResource`, `LeagueResource`, etc.) present every row identically regardless of `source`. The app cannot tell whether a fixture came from the API or from manual entry — that is the whole point.

```
API-Football v3 ─┐
                 ├─►  upsert into canonical tables  ─►  JSON Resources  ─►  Flutter
Admin manual ────┘     (source, external_id, ...)      (one format)
```

---

## Phase 1 — Foundation

**Goal:** project scaffold, dual-guard auth, OTP login for app users, roles/permissions, device tokens, base API/admin structure, settings, versioning. Everything else depends on this phase.

### 1.1 Database Schema

#### `admins`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| name | string | |
| email | string unique | login |
| email_verified_at | timestamp null | |
| password | string | bcrypt |
| phone | string null | |
| avatar | string null | path |
| is_active | bool default true | |
| last_login_at | timestamp null | |
| remember_token | string null | |
| timestamps, softDeletes | | |

#### `users` (Flutter app users)
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| phone | string unique | E.164, with country code |
| phone_verified_at | timestamp null | set on OTP verify |
| name | string null | null until profile complete |
| email | string null unique | optional |
| avatar | string null | |
| supported_club_id | bigint FK→clubs null | optional |
| supported_team_id | bigint FK→teams null | optional |
| governorate | string null | |
| gender | enum(male,female) null | |
| date_of_birth | date null | |
| locale | string default 'ar' | |
| is_active | bool default true | |
| is_banned | bool default false | |
| banned_reason | string null | |
| registration_completed_at | timestamp null | profile form done |
| last_active_at | timestamp null | |
| timestamps, softDeletes | | |

#### `otp_verifications`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| phone | string index | |
| otp_code | string | **hashed** (Hash::make) |
| purpose | enum(login,register,change_phone) | |
| attempts | tinyint default 0 | lock after N |
| expires_at | timestamp | e.g. +5 min |
| verified_at | timestamp null | |
| ip_address | string null | |
| created_at | timestamp | |

#### `device_tokens`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| user_id | bigint FK→users | |
| token | string unique | FCM registration token |
| platform | enum(android,ios) | |
| device_id | string null | |
| device_name | string null | |
| app_version | string null | |
| is_active | bool default true | |
| last_used_at | timestamp null | |
| timestamps | | |

#### `settings`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| group | string index | e.g. general, payment, match |
| key | string | |
| value | text null | scalar or JSON |
| type | enum(string,integer,boolean,json) | cast hint |
| is_public | bool default false | exposed via `/app/config` |
| timestamps | | |
| | | unique (group, key) |

#### `app_versions`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| platform | enum(android,ios) | |
| version | string | semver |
| build_number | integer | |
| min_supported_version | string | below = force update |
| is_force_update | bool default false | |
| changelog_ar | text null | |
| changelog_en | text null | |
| store_url | string | |
| is_active | bool default true | |
| released_at | timestamp null | |
| timestamps | | |

#### Standard Laravel/Sanctum/Spatie tables
- `personal_access_tokens` (Sanctum)
- `sessions`, `password_reset_tokens` (admin)
- `cache`, `cache_locks`, `jobs`, `job_batches`, `failed_jobs` (database queue/cache)
- spatie permission: `roles`, `permissions`, `model_has_roles`, `model_has_permissions`, `role_has_permissions` (with `guard_name`)
- spatie activitylog: `activity_log` (optional)

### 1.2 Models & Relationships

- `Admin` — `HasRoles` (guard `web`).
- `User` — `HasApiTokens`, `HasRoles` (guard `sanctum`); `deviceTokens()`, `supportedClub()`, `store()` (added in Phase 3), `listings()`.
- `OtpVerification`, `DeviceToken`, `Setting`, `AppVersion` — plain models. `Setting` gets a cached `Setting::get($group, $key)` accessor.

### 1.3 Roles & Permissions (seed in `RolesPermissionsSeeder`)

**Admin roles (`web` guard):**
| Role | Scope |
|---|---|
| super-admin | everything (Gate::before bypass) |
| admin | broad management, no admin-user/role management |
| content-editor | match data (leagues, teams, fixtures, manual entry, sync) |
| marketplace-moderator | review/approve/reject listings |
| club-manager | manage club pages & verifications |
| support | read-only + user support actions |

**Admin permissions** (examples; one per resource-action): `manage matches`, `sync matches`, `manage marketplace`, `approve listings`, `manage clubs`, `manage fan-groups`, `manage users`, `ban users`, `manage admins`, `manage roles`, `manage payments`, `send notifications`, `manage settings`, `manage banners`.

**App-user roles (`sanctum` guard):** `seller` (owns a marketplace store), `club-admin` (manages a club page), `group-admin` (manages a fan group). Assigned when the user creates/owns the corresponding entity.

### 1.4 API Endpoints — Auth

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/api/v1/auth/request-otp` | none, `throttle:6,1` | Body: `phone`. Generate OTP, store hashed, send SMS. Returns masked phone + expiry. |
| POST | `/api/v1/auth/verify-otp` | none, `throttle:10,1` | Body: `phone`, `otp`. On success: set `phone_verified_at`, create user if new, return Sanctum token + user + `is_new` flag. |
| POST | `/api/v1/auth/register` | `auth:sanctum` | Complete profile: `name`, `email?`, `supported_club_id?`, `governorate?`. Sets `registration_completed_at`. |
| GET | `/api/v1/auth/me` | `auth:sanctum` | Current user + roles/capabilities. |
| PUT | `/api/v1/auth/profile` | `auth:sanctum` | Update editable profile fields. |
| POST | `/api/v1/auth/logout` | `auth:sanctum` | Revoke current token. |
| DELETE | `/api/v1/auth/account` | `auth:sanctum` | **Account deletion** (App Store / Play requirement). Soft-delete user, revoke tokens, anonymize. |

> **SMS provider:** abstract behind an `OtpSender` interface. Pick an Iraq-capable SMS gateway during integration; keep a `log` driver for local dev that writes the code to the log instead of sending.

### 1.5 Admin Routes (`web.php`) — Foundation

```
# --- Admin JSON API (web.php, prefix /admin/api/v1, `web` middleware group) ---
# Auth (session, web guard). Login/logout/me are NOT behind auth:web for login itself.
POST /admin/api/v1/login          → Auth::guard('web')->attempt(); starts session
POST /admin/api/v1/logout         → invalidate session + regenerate token   [auth:web]
GET  /admin/api/v1/me             → current admin + roles/permissions        [auth:web]
# Admin user & role management (permission: manage admins / manage roles)    [auth:web]
Resource /admin/api/v1/admins
Resource /admin/api/v1/roles
# Settings, versions, banners (later phases reuse this group)                 [auth:web]
Resource /admin/api/v1/settings
Resource /admin/api/v1/app-versions

# --- SPA shell (web.php) — serves the Vue admin for all client-side routes ---
GET  /admin/{any?}                → view('admin')   where any = ^(?!api/).*$
```

**Routing notes:**
- `web.php` routes already receive the `web` middleware group (session + CSRF), so the `XSRF-TOKEN` cookie is issued automatically and admin endpoints get CSRF protection for free. Add `auth:web` (+ `permission:`) to the protected group; keep `login` public within the prefix.
- Define the JSON routes **before** the `/admin/{any?}` fallback; the `^(?!api/).*$` constraint stops the fallback from swallowing `/admin/api/...`.
- The Vue SPA uses Vue Router in **history mode** with base `/admin`, so its login page lives at the browser path `/admin/login` (client-side) while authentication hits `POST /admin/api/v1/login` (JSON).

### 1.6 Acceptance Criteria

- Admin can log in via `POST /admin/api/v1/login` (session established, CSRF enforced); app user tokens **cannot** access admin endpoints and admin sessions **cannot** access `/api/v1/*`.
- The `/admin` SPA shell loads and Vue Router handles client navigation; refreshing any `/admin/*` path serves the app (fallback route works).
- Full OTP cycle works: request → verify → token issued → `me` returns user.
- OTP is hashed at rest, expires, rate-limited, and locks after N attempts.
- Roles/permissions seeded; `super-admin` bypasses gates.
- `/api/v1/auth/account` deletes the account and revokes tokens.
- Every API response conforms to the standard envelope.

---

## Phase 2 — Match Sections

**Goal:** the canonical match store. Sync API-Football v3 into our schema, allow manual entry for uncovered competitions, expose one unified format to the app. Covers leagues, fixtures, live scores, standings, events, lineups, statistics, **top scorers**, plus the **per-fixture social layer (comments / likes / shares) and the predictions system** — all of which apply to **every fixture (API + manual)**.

> **This phase implements the client's detailed "Match Results / Manual Entry" UI spec** (the second PDF). Manual competitions span **10 categories**: Premier League, First Division, Second Division, Third Division, and the national team at six levels (Senior, U-21, U-19, U-17, U-16, U-14). The manual match console (§2.6) mirrors that document's flow: Details → Lineup → Events → Standings, plus Top Scorers, Loyal-Fans comments, and Predictions. Seed these 10 as `leagues` rows (`source=manual`, appropriate `tier`) in the competitions seeder.

### 2.1 Database Schema

> All tables below carry the four canonical columns from §0.9: `source`, `external_id`, `external_payload` (JSON), `last_synced_at`, plus `is_locked` (bool) where noted.

#### `leagues`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| source | enum(api_football,manual) | |
| external_id | unsignedBigInt null index | API-Football league id |
| name_ar | string | |
| name_en | string | |
| type | enum(league,cup) | |
| logo_path | string null | |
| country_name | string null | |
| country_code | string null | |
| country_flag | string null | |
| is_iraqi | bool default false | |
| category | enum(premier,first_div,second_div,third_div,nt_senior,nt_u21,nt_u19,nt_u17,nt_u16,nt_u14,other) null | the 10 manual competition types (per PDF); `other` for API leagues |
| tier | tinyint null | sort weight (1=Premier … then divisions, then NT levels) |
| requires_auth | bool default true | client: login required to view |
| is_featured | bool default false | |
| display_order | int default 0 | |
| is_active | bool default true | |
| is_locked | bool default false | manual override protection |
| external_payload, last_synced_at, timestamps | | |
| | | unique (source, external_id) |

#### `seasons`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| league_id | FK→leagues | |
| source, external_id | | |
| year | smallint | e.g. 2025 |
| label | string null | "2025-2026" |
| start_date | date null | |
| end_date | date null | |
| is_current | bool default false | |
| coverage | json null | API coverage flags |
| timestamps | | |
| | | index (league_id, year) |

#### `venues`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| source, external_id | | |
| name_ar, name_en | string | |
| address | string null | |
| city | string null | |
| capacity | int null | |
| surface | string null | |
| image_path | string null | |
| latitude, longitude | decimal null | |
| external_payload, last_synced_at, timestamps | | |

#### `teams`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| source, external_id (index) | | |
| name_ar, name_en | string | |
| short_code | string null | "MUN" |
| country_name | string null | |
| founded_year | smallint null | |
| is_national | bool default false | |
| logo_path | string null | |
| venue_id | FK→venues null | |
| club_id | FK→clubs null | link to club page (Phase 4) |
| is_active | bool default true | |
| is_locked | bool default false | |
| external_payload, last_synced_at, timestamps | | |
| | | unique (source, external_id) |

#### `players`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| source, external_id (index) | | |
| name_ar, name_en | string | |
| firstname, lastname | string null | |
| date_of_birth | date null | |
| birth_place, birth_country | string null | |
| nationality | string null | |
| height, weight | string null | "180 cm" / "75 kg" |
| photo_path | string null | |
| position | string null | |
| is_injured | bool default false | |
| external_payload, last_synced_at, timestamps | | |
| | | unique (source, external_id) |

#### `coaches`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| source, external_id | | |
| name_ar, name_en | string | |
| firstname, lastname | string null | |
| date_of_birth | date null | |
| nationality | string null | |
| photo_path | string null | |
| external_payload, last_synced_at, timestamps | | |

#### `team_player` (squad, season-aware)
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| team_id | FK→teams | |
| player_id | FK→players | |
| season_id | FK→seasons null | |
| number | tinyint null | shirt number |
| position | string null | |
| is_active | bool default true | |
| timestamps | | unique (team_id, player_id, season_id) |

#### `fixtures`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| source | enum(api_football,manual) | |
| external_id | unsignedBigInt null index | |
| league_id | FK→leagues | |
| season_id | FK→seasons null | |
| round | string null | "Regular Season - 12" |
| home_team_id | FK→teams | |
| away_team_id | FK→teams | |
| venue_id | FK→venues null | |
| referee | string null | center/main referee (API fills this; manual = 1st official) |
| referee_assistant_1 | string null | linesman 1 (manual) |
| referee_assistant_2 | string null | linesman 2 (manual) |
| referee_fourth_official | string null | 4th official (manual) |
| supervisor | string null | match supervisor (manual) |
| match_datetime | datetime index | UTC |
| timezone | string default 'UTC' | |
| status_short | string | API code: NS,1H,HT,2H,FT,LIVE… |
| status_long | string | "Match Finished" |
| status_group | enum(scheduled,live,finished,postponed,cancelled) index | **normalized** (see §2.3) |
| elapsed | tinyint null | live minute |
| home_goals, away_goals | tinyint null | current score |
| home_ht, away_ht | tinyint null | halftime |
| home_ft, away_ft | tinyint null | fulltime |
| home_et, away_et | tinyint null | extra time |
| home_pen, away_pen | tinyint null | penalties |
| winner | enum(home,away,draw) null | |
| is_featured | bool default false | |
| has_lineups, has_events, has_statistics | bool default false | |
| likes_count | int default 0 | social counter |
| comments_count | int default 0 | match-feed comments |
| shares_count | int default 0 | share taps |
| predictions_count | int default 0 | total predictions |
| predict_home_count, predict_draw_count, predict_away_count | int default 0 | aggregate for % (out of 100) |
| predictions_settled | bool default false | set when correctness computed at FT |
| is_locked | bool default false | |
| external_payload, last_synced_at, timestamps | | |
| | | unique (source, external_id); index (status_group, match_datetime); index (league_id, season_id) |

#### `standings`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| league_id | FK→leagues | |
| season_id | FK→seasons | |
| team_id | FK→teams | |
| source | | |
| group_label | string null | grouped comps |
| rank | smallint | |
| points | smallint | |
| goals_diff | smallint | |
| played, win, draw, lose | smallint | overall |
| goals_for, goals_against | smallint | |
| home_* / away_* | smallint | split records (played,win,draw,lose,goals_for,goals_against) |
| form | string null | "WWDLW" |
| status | string null | same/up/down |
| description | string null | "Promotion - Champions League" |
| display_order | int | |
| last_synced_at, timestamps | | |
| | | unique (league_id, season_id, team_id, group_label) |

#### `fixture_events`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| fixture_id | FK→fixtures index | |
| source | | |
| team_id | FK→teams null | which club's box (per PDF, events log under one of the two clubs) |
| player_id | FK→players null | primary player (scorer / carded / **player coming ON** for subst) |
| assist_player_id | FK→players null | assist (goal) / **player going OFF** for subst |
| player_name, assist_name | string null | fallback when no FK (manual entry types names) |
| elapsed | tinyint | match minute |
| extra | tinyint null | +stoppage |
| type | enum(goal,card,subst,var,kickoff,half_end,penalty,match_end,match_cancelled,match_postponed) | expanded for manual flow |
| detail | string | see mapping below |
| comments | string null | |
| display_order | int | |
| timestamps | | |

**Event-keyword → `type`/`detail` mapping (from the client UI spec).** The manual console exposes a per-team "Event" search bar; each keyword writes a row and pins it to the minute on the timeline:

| Client keyword | `type` | `detail` | Fields captured |
|---|---|---|---|
| Goal | `goal` | Normal Goal / Penalty / Own Goal | scorer → `player_id`/`player_name`; assist → `assist_*`; also bumps the `top_scorers` list |
| Kickoff / Start | `kickoff` | Start | minute only |
| Yellow Card | `card` | Yellow Card | player |
| Red Card | `card` | Red Card | player |
| Sending-off | `card` | Second Yellow → Red | player |
| Substitution | `subst` | Substitution | ON → `player_id`/`player_name`, OFF → `assist_*` |
| Penalty | `penalty` | Awarded / Scored / Missed | player |
| End of Half | `half_end` | First Half / Second Half | minute (+ stoppage in `extra`) |
| End of Match | `match_end` | Full Time | **also sets fixture `status_group=finished`, closes the console, triggers prediction settlement** |
| Match Cancelled | `match_cancelled` | Cancelled | **sets `status_group=cancelled`, closes the console** |
| Match Postponed | `match_postponed` | Postponed | **sets `status_group=postponed`, closes the console** |

> API-Football sync maps its native `Goal/Card/subst/Var` onto `goal/card/subst/var`; the extra types are manual-only.

#### `fixture_lineups`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| fixture_id | FK→fixtures | |
| team_id | FK→teams | |
| source | | |
| formation | string null | "4-3-3" |
| coach_id | FK→coaches null | |
| coach_name, coach_photo | string null | |
| timestamps | | unique (fixture_id, team_id) |

#### `fixture_lineup_players`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| fixture_lineup_id | FK | |
| player_id | FK→players null | |
| player_name | string | |
| number | tinyint null | |
| position | string null | G/D/M/F |
| grid | string null | "1:1" pitch coords |
| is_starter | bool | startXI vs subs |
| timestamps | | |

#### `fixture_statistics`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| fixture_id | FK index | |
| team_id | FK→teams | |
| source | | |
| type | string | "Shots on Goal","Ball Possession" |
| value | string null | raw ("50%") |
| value_numeric | decimal null | parsed |
| display_order | int | |
| timestamps | | |

#### `fixture_broadcasts` (NEW — broadcasting channels + commentators, per PDF)
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| fixture_id | FK→fixtures index | |
| channel_name | string | "beIN Max 2" |
| channel_logo_path | string null | |
| stream_url | string null | manually uploaded link if broadcasting |
| commentator_name | string null | |
| display_order | int | |
| timestamps | | |

#### `top_scorers` (NEW — admin-managed scorer list, per PDF)
> Replaces the earlier "derived/cached" approach. Admin maintains an **open, editable** list per league+season; adding goals auto-reorders the rank. API competitions may also be synced here.

| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| source | enum(api_football,manual) | |
| league_id | FK→leagues index | |
| season_id | FK→seasons null | |
| player_id | FK→players null | link if exists |
| player_name | string | manual fallback |
| player_photo_path | string null | |
| team_id | FK→teams null | |
| team_name | string null | club label |
| goals | smallint default 0 | tally |
| assists | smallint null | optional (API) |
| penalties | smallint null | optional |
| rank | smallint null | recomputed on goals change |
| display_order | int | |
| last_synced_at, timestamps | | |
| | | index (league_id, season_id); unique (league_id, season_id, player_id) when player_id set |

#### `fixture_predictions` (NEW — predictions system, ALL fixtures)
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| fixture_id | FK→fixtures index | |
| user_id | FK→users | |
| predicted_home_score | tinyint | from the +/- counter |
| predicted_away_score | tinyint | |
| predicted_outcome | enum(home,draw,away) | derived from the two scores |
| is_correct | bool null | set at FT (outcome match) |
| is_exact_score | bool null | set at FT (exact scoreline) |
| likes_count | int default 0 | other users can like a prediction |
| created_at, updated_at | | |
| | | unique (fixture_id, user_id) — one per user; index (fixture_id, is_correct) |

> Predictions are accepted **only while `status_group=scheduled`** (locked at kickoff). Aggregate `predict_*_count` live on `fixtures` for the % display. At FT a job (§2.4) settles `is_correct`/`is_exact_score`; the "correct predictions" list is ordered **oldest-first** (per PDF).

#### `comments` (NEW — polymorphic social, threaded)
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| user_id | FK→users | |
| commentable_type | string | morph (Fixture, FixturePrediction) |
| commentable_id | bigint | |
| context | enum(match,prediction) default match | two separate feeds on a fixture (Loyal-Fans vs predictions page) |
| parent_id | FK→comments null | replies (threading) |
| body | text | |
| likes_count | int default 0 | |
| replies_count | int default 0 | |
| is_hidden | bool default false | moderation |
| timestamps, softDeletes | | index (commentable_type, commentable_id, context); index (parent_id) |

#### `likes` (NEW — polymorphic likes)
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| user_id | FK→users | |
| likeable_type | string | morph (Fixture, Comment, FixturePrediction) |
| likeable_id | bigint | |
| created_at | timestamp | |
| | | unique (user_id, likeable_type, likeable_id); index (likeable_type, likeable_id) |

> "Share" is a client share-sheet action + a server counter: `POST /fixtures/{id}/share` increments `fixtures.shares_count` (optionally log to a `fixture_shares` table if analytics are needed later).

#### `api_football_sync_logs`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| endpoint | string | "fixtures" |
| parameters | json | |
| status | enum(success,failed,rate_limited) | |
| http_status | smallint null | |
| records_processed | int null | |
| requests_remaining | int null | from response headers |
| error_message | text null | |
| duration_ms | int null | |
| created_at | timestamp | |

### 2.2 API-Football v3 → Schema Mapping

Base URL `https://v3.football.api-sports.io`, header `x-apisports-key: {API_FOOTBALL_KEY}`. Response shape: `{ get, parameters, errors, results, paging, response[] }`.

| API-Football endpoint | Maps to | Key fields |
|---|---|---|
| `GET /leagues` | `leagues` + `seasons` | `league.id/name/type/logo`, `country.*`, `seasons[]` |
| `GET /teams?league=&season=` | `teams` (+ `venues`) | `team.id/name/code/founded/logo`, `venue.*` |
| `GET /players/squads?team=` | `team_player` + `players` | squad list per team |
| `GET /standings?league=&season=` | `standings` | `league.standings[][]` (groups → teams) |
| `GET /fixtures?league=&season=` | `fixtures` | `fixture.*`, `league.*`, `teams.*`, `goals.*`, `score.*` |
| `GET /fixtures?live=all` | `fixtures` (live upsert) | live subset |
| `GET /fixtures?id=` | `fixtures` detail | single |
| `GET /fixtures/events?fixture=` | `fixture_events` | `time/team/player/assist/type/detail` |
| `GET /fixtures/lineups?fixture=` | `fixture_lineups` (+players) | `formation/startXI/substitutes/coach` |
| `GET /fixtures/statistics?fixture=` | `fixture_statistics` | `statistics[]` type/value |
| `GET /players/topscorers?league=&season=` | `top_scorers` | upsert scorers (name/photo/team/goals); manual rows coexist |
| `GET /coachs?team=` | `coaches` | coach profile |

Upsert key for all: `where source='api_football' AND external_id=<id>`. Skip rows where `is_locked = true`.

### 2.3 Status Normalization (API → `status_group`)

| API `status.short` | `status_group` |
|---|---|
| TBD, NS | scheduled |
| 1H, HT, 2H, ET, BT, P, SUSP, INT, LIVE | live |
| FT, AET, PEN | finished |
| PST, CANC, ABD, AWD, WO | postponed / cancelled |

Implement as a `FixtureStatus` enum with a `group()` method. Store both raw (`status_short`/`status_long`) and normalized (`status_group`) so the app can filter simply on `status_group=live`.

### 2.4 Services, Jobs, Commands

**`App\Services\ApiFootball\ApiFootballClient`** — thin HTTP wrapper: builds requests, injects key + timezone, parses the envelope, records `api_football_sync_logs`, reads `x-ratelimit-requests-remaining` headers, throws on `errors[]`.

**DTOs** (`Support/DataTransferObjects/`) — one per resource (`FixtureData`, `StandingData`, …) to decouple API shape from models.

**Sync services** (`LeagueSync`, `TeamSync`, `FixtureSync`, `StandingSync`, `FixtureDetailSync`, `TopScorerSync`) — transform DTOs → upsert.

**Domain services / jobs (NEW):**
- `TopScorerService::recomputeRanks(league, season)` — re-sorts by `goals` desc and rewrites `rank`. Called after any scorer edit or when a Goal event is logged.
- `SettleFixturePredictionsJob` (queued) — on a fixture reaching `finished` (via `sync:live` **or** the manual "End of Match" event), set `is_correct` (outcome vs `winner`) and `is_exact_score` (scoreline match) for every prediction, then mark `predictions_settled=true`.
- Optional automation: when an admin logs a **Goal** event in the console, upsert/increment the scorer in `top_scorers` for that league+season and call `recomputeRanks` (toggle via setting `matches.auto_top_scorers`).
- Counter maintenance: model observers keep `fixtures.likes_count/comments_count/shares_count/predict_*_count` and `comments.likes_count/replies_count` in sync transactionally on like/comment/prediction writes.

**Console commands:**
| Command | Cadence | Action |
|---|---|---|
| `sync:leagues {--iraqi}` | weekly | leagues + seasons |
| `sync:teams {league} {season}` | weekly | teams + venues + squads |
| `sync:standings {league} {season}` | hourly (match days) | standings |
| `sync:fixtures {league} {season}` | daily | fixtures for season |
| `sync:top-scorers {league} {season}` | daily (match days) | upsert top scorers, recompute ranks |
| `sync:live` | every `API_FOOTBALL_LIVE_POLL_SECONDS` | `fixtures?live=all` upsert; on transition to finished, pull events/lineups/stats **and dispatch `SettleFixturePredictionsJob`** |
| `sync:fixture-details {fixture}` | on demand / post-match | events, lineups, statistics |

Schedule in `routes/console.php`. **Guard every command** against `API_FOOTBALL_DAILY_LIMIT` using a daily counter in `settings`/cache; abort + log `rate_limited` when exceeded. Run heavy syncs as **queued jobs** on the `database` queue.

> **Live freshness without WebSockets:** no Reverb/Redis (per constraints). The app polls `GET /api/v1/fixtures/live` every 30–60s. Goal/key events also trigger an **FCM push** (Phase 7) so users get alerts without the app open.

### 2.5 API Endpoints — Matches

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/api/v1/leagues` | sanctum | active leagues, ordered by `tier`/`display_order`; `?is_iraqi=1` |
| GET | `/api/v1/leagues/{id}` | sanctum | league + current season |
| GET | `/api/v1/leagues/{id}/standings` | sanctum | standings (current/`?season=`). Gated by `requires_auth`. |
| GET | `/api/v1/leagues/{id}/fixtures` | sanctum | fixtures, `?status_group=&date=&round=` |
| GET | `/api/v1/leagues/{id}/top-scorers` | sanctum | top scorers (from `top_scorers`, ranked); `?season=` |
| GET | `/api/v1/fixtures` | sanctum | `?date=&league=&team=&status_group=` |
| GET | `/api/v1/fixtures/live` | sanctum | all live fixtures (poll target) |
| GET | `/api/v1/fixtures/{id}` | sanctum | full detail (score, events, lineups, stats, venue, **referee crew + supervisor**, **broadcasts**, social counters, user's own prediction) |
| GET | `/api/v1/fixtures/{id}/events` | sanctum | timeline |
| GET | `/api/v1/fixtures/{id}/lineups` | sanctum | formations + XI/subs |
| GET | `/api/v1/fixtures/{id}/statistics` | sanctum | per-team stats |
| GET | `/api/v1/fixtures/{id}/broadcasts` | sanctum | channels + commentators |
| GET | `/api/v1/teams/{id}` | sanctum | team + venue |
| GET | `/api/v1/teams/{id}/fixtures` | sanctum | upcoming + results |
| GET | `/api/v1/teams/{id}/squad` | sanctum | current squad |
| GET | `/api/v1/players/{id}` | sanctum | player profile |
| **Predictions** | | | |
| GET | `/api/v1/fixtures/{id}/predictions/summary` | sanctum | %s out of 100 (home/draw/away) + counts + caller's own prediction |
| POST | `/api/v1/fixtures/{id}/predictions` | sanctum | create/update own prediction (scoreline → outcome); **rejected once kicked off** |
| GET | `/api/v1/fixtures/{id}/predictions/correct` | sanctum | correct predictions, **oldest-first** (after FT) |
| POST/DELETE | `/api/v1/predictions/{id}/like` | sanctum | like/unlike another user's prediction |
| **Comments & social** | | | |
| GET | `/api/v1/fixtures/{id}/comments` | sanctum | `?context=match\|prediction&sort=most_liked\|most_replied\|newest\|oldest`, paginated, top-level |
| POST | `/api/v1/fixtures/{id}/comments` | sanctum | add comment/reply (`context`, `body`, `parent_id?`) |
| GET | `/api/v1/comments/{id}/replies` | sanctum | replies thread |
| PUT/DELETE | `/api/v1/comments/{id}` | sanctum + owner | edit/delete own |
| POST/DELETE | `/api/v1/comments/{id}/like` | sanctum | like/unlike a comment |
| POST/DELETE | `/api/v1/fixtures/{id}/like` | sanctum | like/unlike a fixture |
| POST | `/api/v1/fixtures/{id}/share` | sanctum | increment `shares_count` |

**Resources** (`FixtureResource`, `FixtureDetailResource`, `LeagueResource`, `StandingResource`, `TeamResource`, `PlayerResource`, `FixtureEventResource`, `LineupResource`, `StatisticResource`, `BroadcastResource`, `TopScorerResource`, `PredictionSummaryResource`, `PredictionResource`, `CommentResource`) — produce the single canonical format. `FixtureDetailResource` adds `officials` (crew + supervisor), `broadcasts`, `social` (likes/comments/shares counts + `liked_by_me`), and `prediction` (summary + `my_prediction`). Example `FixtureResource`:

```json
{
  "id": 1421,
  "league": { "id": 7, "name": "الدوري العراقي الممتاز", "logo": "...", "round": "الجولة 12" },
  "status": { "short": "2H", "group": "live", "long": "Second Half", "elapsed": 67 },
  "datetime": "2026-07-05T17:00:00Z",
  "venue": { "id": 3, "name": "ملعب البصرة الدولي", "city": "البصرة" },
  "home": { "id": 33, "name": "القوة الجوية", "logo": "...", "goals": 2, "winner": true },
  "away": { "id": 41, "name": "الزوراء", "logo": "...", "goals": 1, "winner": false },
  "score": { "halftime": {"home":1,"away":0}, "fulltime": null },
  "has": { "events": true, "lineups": true, "statistics": true }
}
```

### 2.6 Admin Routes (`web.php`) — Matches

```
Resource /admin/leagues          # CRUD + manual entry, set tier/requires_auth/order, Arabic names
Resource /admin/seasons
Resource /admin/teams            # CRUD + manual entry, link team↔club, Arabic overrides
Resource /admin/venues
Resource /admin/players
Resource /admin/fixtures         # CRUD + manual scoreboard; edit officials crew + supervisor
Resource /admin/standings        # manual standings editor (20 teams, all 9 columns)
Resource /admin/fixtures/{fixture}/broadcasts   # channels + commentators + stream links
Resource /admin/fixtures/{fixture}/lineups      # pitch builder: slots, photo/name/number, grid, formation
Resource /admin/fixtures/{fixture}/events       # live event entry (keyword → box → minute)
Resource /admin/leagues/{league}/top-scorers    # add/edit/remove scorers, set goals (auto-rank)
# Predictions oversight (read)
GET  /admin/fixtures/{fixture}/predictions       # list + settled stats
# Comments moderation (permission: manage matches / moderate comments)
GET    /admin/comments                           # filter by fixture/context/hidden
POST   /admin/comments/{comment}/hide
DELETE /admin/comments/{comment}
# Sync controls (permission: sync matches)
POST /admin/sync/leagues
POST /admin/sync/teams
POST /admin/sync/standings
POST /admin/sync/fixtures
POST /admin/sync/top-scorers
POST /admin/fixtures/{fixture}/sync-details
POST /admin/leagues/{league}/toggle-lock
GET  /admin/sync/logs            # view api_football_sync_logs
```

> Per the §0.4 convention, these are JSON endpoints under `/admin/api/v1/*`, consumed by the Vue admin SPA.

**Manual match console flow (mirrors the client UI spec).** A single console screen drives a manual fixture through its lifecycle. Standings are owned by the **Competitions Committee** role (use `content-editor`, or add a dedicated `competitions-committee` role):

1. **Details** — pick tournament (one of the 10 categories) + round (1–2 digit picker), type stadium, the 4-person referee crew, supervisor, date, time; attach broadcast channels (+ commentators + stream link).
2. **Lineup** — pitch builder with 11 slots per side; tap a slot to set player photo/name/number, drag to position (writes `grid`); set the formation string (e.g. `4-3-2-1`); add substitutes to the bench table.
3. **Events** — after kickoff, a per-team "Event" picker; choosing a keyword opens its box, captures player/minute, and pins it to the timeline (see the mapping in §2.1). Selecting **End of Match / Cancelled / Postponed** sets `status_group`, **closes the console**, and (for End of Match) **dispatches prediction settlement**.
4. **Standings** — the 20-team editor (position, played, W/D/L, for, against, GD, points; 3/1/0).
5. **Top Scorers** — open editable list; adding goals to a scorer auto-reorders rank.

Manual-entry forms write rows with `source='manual'`.

### 2.7 Acceptance Criteria

- `sync:leagues --iraqi`, `sync:teams`, `sync:fixtures`, `sync:standings` populate canonical tables; re-running upserts without duplicates.
- `sync:live` updates live scores within the poll window; status transitions flip `status_group` correctly and pull details on finish.
- A manually-entered fixture (no `external_id`) appears in `/api/v1/fixtures` in the **same JSON shape** as an API-Football fixture.
- Locked rows are never overwritten by sync.
- Standings/fixtures endpoints enforce auth per `requires_auth`.
- Sync respects the daily request cap and logs every call.
- The 10 manual competition categories are seeded; an editor can run the full console flow (Details → Lineup → Events → Standings → Top Scorers) and selecting "End of Match" closes the console and finalizes the fixture.
- Lineup builder produces an 11-slot formation per team with `grid` positions and a substitutes table; the fixture detail returns it in the canonical lineup shape.
- Event keywords log to the timeline with correct `type`/`detail`/minute; status-changing events update `status_group`.
- Top scorers: adding goals re-ranks the list; `/leagues/{id}/top-scorers` returns it ordered.
- Predictions: a user can predict before kickoff but not after; the summary returns %s out of 100; at FT correctness is settled and the correct list is oldest-first.
- Comments/likes/shares work on every fixture (API + manual); the match feed sorts by most-liked/most-replied/newest/oldest; counters stay consistent; admins can hide/delete comments.

---

## Phase 3 — Sports Marketplace ("Stadium Market")

**Goal:** subscribers create a store and publish category-based listing "cards" (players, coaches, lawyers, accountants, directors, supervisors, tactical plans, specialists). IQD pricing (USD for foreigners). Each listing is paid (Phase 6) before review/publish. Includes the **commission-vs-direct-contact** monetization toggle the client asked about.

### 3.1 Category Model

The client lists ~16 category types with shared fields and category-specific fields. Use **one base `listings` table + a `marketplace_categories` table whose `field_schema` JSON drives category-specific fields and admin form rendering** (avoids 16 separate tables).

### 3.2 Database Schema

#### `stores`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| user_id | FK→users unique | one store per user |
| name_ar | string | |
| name_en | string null | |
| slug | string unique | |
| logo_path, cover_path | string null | |
| bio_ar, bio_en | text null | |
| phone, whatsapp, email | string null | |
| governorate, city | string null | |
| is_verified | bool default false | |
| verified_at | timestamp null | |
| status | enum(pending,active,suspended) default pending | |
| timestamps, softDeletes | | |

#### `marketplace_categories`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| key | string unique | player_profile, professional_no_agent, professional_with_agent, coach, assistant_coach, gk_coach, fitness_coach, ex_manager, lawyer, accountant, executive_director, team_supervisor, tactical_plan, sports_specialist, sports_lawyer |
| parent_id | FK self null | group coach sub-types under "Coaches" |
| name_ar, name_en | string | |
| description_ar, description_en | text null | |
| icon_path | string null | |
| base_price | decimal(12,2) | |
| currency | enum(IQD,USD) default IQD | |
| is_free | bool default false | e.g. basic player profile |
| pricing_note | string null | |
| field_schema | json | category-specific field definitions |
| requires_contact_button | bool default true | monetization toggle (see §3.5) |
| listing_duration_days | int null | null = no expiry |
| display_order | int | |
| is_active | bool default true | |
| timestamps | | |

> Seed all categories + prices in `MarketplaceCategoriesSeeder` from the client doc (player profile, professional w/ & w/o agent @ 20,000 IQD, coaches/lawyer/accountant/director/supervisor/tactical/specialist @ 25,000 IQD, etc.).

#### `listings`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| store_id | FK→stores | |
| user_id | FK→users | |
| category_id | FK→marketplace_categories | |
| title_ar | string | |
| title_en | string null | |
| slug | string unique | |
| status | enum(draft,pending_payment,pending_review,published,rejected,expired,suspended) | |
| full_name | string null | |
| photo_path | string null | |
| date_of_birth | date null | |
| age | tinyint null | or compute from DOB |
| country, nationality | string null | |
| governorate, city | string null | |
| contact_phone, contact_whatsapp, contact_email | string null | |
| show_contact | bool default true | per-listing override of category default |
| attributes | json null | category-specific (position, height, weight, preferred_foot, coaching_license, target_team_category, practice_areas, languages, hourly_rate, …) |
| cv_path | string null | |
| rejection_reason | string null | |
| reviewed_by | FK→admins null | |
| reviewed_at | timestamp null | |
| is_featured | bool default false | |
| featured_until | timestamp null | |
| views_count | int default 0 | |
| contacts_count | int default 0 | |
| payment_id | FK→payments null | |
| published_at | timestamp null | |
| expires_at | timestamp null | |
| timestamps, softDeletes | | |
| | | index (category_id, status); index (governorate) |

#### `listing_media`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| listing_id | FK | |
| type | enum(image,video,document) | |
| path | string | |
| thumbnail_path | string null | |
| title | string null | |
| mime_type | string null | |
| size | bigint null | bytes |
| display_order | int | |
| timestamps | | |

> Enforce per-category media limits (e.g. images, video count) in the Form Request based on `field_schema`.

#### `listing_contacts` (monetization analytics)
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| listing_id | FK | |
| user_id | FK→users null | viewer |
| contact_type | enum(phone,whatsapp,email,button) | |
| ip_address | string null | |
| created_at | timestamp | |

### 3.3 Models & Relationships

- `Store` belongsTo `User`, hasMany `Listing`.
- `MarketplaceCategory` self-referential (`parent`/`children`), hasMany `Listing`.
- `Listing` belongsTo `Store`, `User`, `MarketplaceCategory`, `Payment`; hasMany `ListingMedia`, `ListingContact`. Casts `attributes` to array. Auto-slug + `age` accessor.
- When a user creates their first store → assign `seller` role (sanctum guard).

### 3.4 API Endpoints — Marketplace

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/api/v1/marketplace/categories` | sanctum | category tree + prices + field schema |
| GET | `/api/v1/marketplace/listings` | sanctum | `?category=&governorate=&q=&featured=1`; only `published` |
| GET | `/api/v1/marketplace/listings/{id}` | sanctum | detail; increments `views_count` |
| POST | `/api/v1/marketplace/listings/{id}/contact` | sanctum | log `listing_contacts`; returns contact info **iff** `show_contact` |
| GET | `/api/v1/marketplace/my-store` | sanctum | current user's store |
| POST | `/api/v1/marketplace/stores` | sanctum | create store (→ `seller` role) |
| PUT | `/api/v1/marketplace/stores/{id}` | sanctum + owner | update |
| GET | `/api/v1/marketplace/my-listings` | sanctum | own listings (all statuses) |
| POST | `/api/v1/marketplace/listings` | sanctum + owner | create as `draft`; if category not free → `pending_payment` then payment (Phase 6) |
| PUT | `/api/v1/marketplace/listings/{id}` | sanctum + owner | edit (re-enters `pending_review`) |
| DELETE | `/api/v1/marketplace/listings/{id}` | sanctum + owner | soft delete |
| POST | `/api/v1/marketplace/listings/{id}/media` | sanctum + owner | upload (limit-checked) |

**Listing lifecycle:** `draft → pending_payment → (pay) → pending_review → published` (or `rejected`). Free categories skip payment. Expiry job moves `published → expired` after `expires_at`.

### 3.5 Monetization Toggle (client's open question)

The client asked whether to take commission up-front or just show a contact button and let deals happen off-platform. Support **both**, switchable per category and per listing, settings-driven:

- `marketplace_categories.requires_contact_button` + `listings.show_contact` control whether contact info is exposed.
- A `settings` flag `marketplace.mode` = `contact` (show contact, revenue = listing fee only) or `commission` (hide contact, broker via platform).
- `listing_contacts` logs every reveal/click so the client can later measure leakage and decide. Build the schema to support either model without migration.

### 3.6 Admin Routes (`web.php`) — Marketplace

```
Resource /admin/marketplace/categories     # manage categories, prices, field_schema, contact mode
Resource /admin/marketplace/stores         # verify/suspend
GET      /admin/marketplace/listings       # queue + filters by status
GET      /admin/marketplace/listings/{id}
POST     /admin/marketplace/listings/{id}/approve
POST     /admin/marketplace/listings/{id}/reject     # reason
POST     /admin/marketplace/listings/{id}/feature
GET      /admin/marketplace/contacts/report          # leakage analytics
```

### 3.7 Acceptance Criteria

- Seeded categories match the client's list, prices, and currencies.
- Paid listing cannot publish until its `payment_id` is `paid`; free listing publishes after review.
- `field_schema` drives category-specific fields end-to-end (create → store in `attributes` → return in Resource).
- Contact button respects `show_contact`/category mode and logs to `listing_contacts`.
- Media limits enforced per category.

---

## Phase 4 — Sports Clubs

**Goal:** rich club pages (free for now; fee at season start). Board org-chart, staff, titles archive, former captains, competitions, news. Optional link to a match-data `team`. Verification link between club and members carrying its logo.

### 4.1 Database Schema

#### `clubs`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| team_id | FK→teams null | link to match-data team |
| name_ar, name_en | string | |
| slug | string unique | |
| logo_path, cover_path | string null | |
| founded_year | smallint null | |
| description_ar, description_en | text null | |
| governorate, city, address | string null | |
| latitude, longitude | decimal null | GPS (client requirement) |
| phone, email, website | string null | |
| facebook, instagram, twitter | string null | |
| managed_by | FK→users null | club-admin app user |
| is_verified | bool default false | |
| verified_at | timestamp null | |
| status | enum(pending,active,suspended) default pending | |
| is_active | bool default true | |
| display_order | int | |
| timestamps, softDeletes | | |

#### `club_board_members` (org chart)
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| club_id | FK | |
| parent_id | FK self null | hierarchy (top→down) |
| name_ar, name_en | string | |
| position_ar, position_en | string | |
| photo_path | string null | |
| display_order | int | |
| is_active | bool default true | |
| timestamps | | |

#### `club_staff`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| club_id | FK | |
| name_ar, name_en | string | |
| role_ar, role_en | string | |
| type | enum(coaching,technical,medical,admin) | |
| photo_path | string null | |
| bio | text null | |
| display_order | int | |
| timestamps | | |

#### `club_titles` (championships archive)
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| club_id | FK | |
| title_ar, title_en | string | |
| competition_ar, competition_en | string null | |
| season | string null | |
| year | smallint null | |
| count | smallint null | times won |
| image_path | string null | |
| display_order | int | |
| timestamps | | |

#### `club_captains` (former captains)
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| club_id | FK | |
| name_ar, name_en | string | |
| photo_path | string null | |
| period_from, period_to | smallint null | years |
| description | text null | |
| display_order | int | |
| timestamps | | |

#### `club_competitions`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| club_id | FK | |
| league_id | FK→leagues null | or free text |
| name_ar, name_en | string null | |
| season | string null | |
| status | enum(active,past) | |
| display_order | int | |
| timestamps | | |

#### `club_news`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| club_id | FK | |
| title_ar, title_en | string | |
| slug | string | |
| excerpt_ar, excerpt_en | text null | |
| content_ar | longtext | |
| content_en | longtext null | |
| cover_path | string null | |
| author_name | string null | |
| is_published | bool default false | |
| published_at | timestamp null | |
| views_count | int default 0 | |
| timestamps | | index (club_id, is_published) |

#### `club_news_media`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | club_news_id FK, type(image,video), path, display_order, timestamps |

#### `club_verifications` (polymorphic — covers listings, fan groups, users)
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| club_id | FK | |
| verifiable_type | string | morph (Listing/FanGroup/User) |
| verifiable_id | bigint | |
| status | enum(pending,approved,rejected) default pending | |
| method | enum(message,voice,video) | |
| note | text null | |
| requested_by | FK→users null | |
| reviewed_by | FK→users null | club admin |
| reviewed_at | timestamp null | |
| timestamps | | index (verifiable_type, verifiable_id) |

> **Season gate:** the verification feature "activates at season start" per the client. Gate it behind a `settings` flag `clubs.verification_enabled` so it can be switched on later.

### 4.2 API Endpoints — Clubs

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/api/v1/clubs` | sanctum | `?governorate=&q=` |
| GET | `/api/v1/clubs/{id}` | sanctum | full page (board, staff, titles, captains, competitions) |
| GET | `/api/v1/clubs/{id}/news` | sanctum | published news |
| GET | `/api/v1/clubs/{id}/news/{newsId}` | sanctum | article; increments views |
| POST | `/api/v1/clubs/{id}/verify-request` | sanctum | member requests verification (if enabled) |
| GET | `/api/v1/my-club` | sanctum + club-admin | managed club |
| PUT | `/api/v1/my-club` | sanctum + club-admin | update |
| (nested CRUD) | board/staff/titles/captains/news under `/api/v1/my-club/*` | sanctum + club-admin | manage own club content |

### 4.3 Admin Routes (`web.php`) — Clubs

```
Resource /admin/clubs                          # CRUD, verify, assign managed_by, link team
Nested:  /admin/clubs/{club}/board|staff|titles|captains|competitions|news
GET      /admin/clubs/verifications            # review queue
POST     /admin/clubs/verifications/{id}/approve
POST     /admin/clubs/verifications/{id}/reject
```

### 4.4 Acceptance Criteria

- `/api/v1/clubs/{id}` returns the complete page with board renderable as an org chart (`parent_id`).
- Club can optionally link to a `team`; users can set `supported_club_id`.
- Verification flow works when enabled and is hidden when the season flag is off.

---

## Phase 5 — Fan Groups (Ultras)

**Goal:** official/independent supporter groups with logo, founding year, official documents, photo archive (max 100), video archive (max 30), chants archive (max 20, video), member verification. Free now; fee at season start.

### 5.1 Database Schema

#### `fan_groups`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| club_id | FK→clubs null | affiliated club |
| name_ar, name_en | string | |
| slug | string unique | |
| founded_year | smallint null | |
| club_logo_path | string null | |
| group_logo_path | string null | |
| cover_path | string null | |
| description_ar, description_en | text null | |
| governorate, city | string null | |
| phone, facebook, instagram, twitter | string null | |
| managed_by | FK→users null | group-admin |
| is_official | bool default false | recognized by club |
| is_verified | bool default false | |
| verified_at | timestamp null | |
| status | enum(pending,active,suspended) default pending | |
| is_active | bool default true | |
| display_order | int | |
| timestamps, softDeletes | | |

#### `fan_group_documents`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | fan_group_id FK, title_ar/en null, path, mime_type, size null, display_order, timestamps |

#### `fan_group_media` (photo archive ≤100, video archive ≤30)
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| fan_group_id | FK | |
| type | enum(image,video) | |
| path | string | |
| thumbnail_path | string null | |
| title | string null | |
| display_order | int | |
| timestamps | | |

> Enforce in Form Request: ≤100 `image`, ≤30 `video` per group.

#### `fan_group_chants` (chants ≤20, as video)
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| fan_group_id | FK | |
| title_ar, title_en | string null | |
| video_path | string | |
| thumbnail_path | string null | |
| lyrics | text null | |
| display_order | int | |
| timestamps | | |

> Enforce ≤20 chants per group.

#### `fan_group_verifications`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | fan_group_id FK, user_id FK null, status enum(pending,approved,rejected), method enum(message,voice,video), note null, reviewed_by FK null, reviewed_at null, timestamps |

### 5.2 API Endpoints — Fan Groups

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/api/v1/fan-groups` | sanctum | `?club=&governorate=&q=` |
| GET | `/api/v1/fan-groups/{id}` | sanctum | profile + documents |
| GET | `/api/v1/fan-groups/{id}/media` | sanctum | `?type=image\|video`, paginated |
| GET | `/api/v1/fan-groups/{id}/chants` | sanctum | chants |
| POST | `/api/v1/fan-groups/{id}/verify-request` | sanctum | join/verify (if enabled) |
| GET / PUT | `/api/v1/my-fan-group` | sanctum + group-admin | manage own group |
| (nested CRUD) | media/chants/documents under `/api/v1/my-fan-group/*` | sanctum + group-admin | limit-checked |

### 5.3 Admin Routes (`web.php`) — Fan Groups

```
Resource /admin/fan-groups                     # CRUD, verify, assign managed_by
Nested:  /admin/fan-groups/{group}/media|chants|documents
GET      /admin/fan-groups/verifications
POST     /admin/fan-groups/verifications/{id}/approve|reject
```

### 5.4 Acceptance Criteria

- Archive limits enforced (100/30/20) with clear 422 messages.
- Group profile returns logos, documents, and paginated media.
- Verification gated by season flag like clubs.

---

## Phase 6 — Payments (ZainCash + FIB)

**Goal:** one-time payments for marketplace listings (and future store/club/group fees) via ZainCash and FIB, IQD primary. Polymorphic so any entity can be paid for.

### 6.1 Database Schema

#### `payments`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| user_id | FK→users | |
| payable_type | string | morph (Listing, Store, …) |
| payable_id | bigint | |
| payment_number | string unique | our reference |
| gateway | enum(zaincash,fib,manual) | |
| amount | decimal(12,2) | |
| currency | enum(IQD,USD) default IQD | |
| status | enum(pending,processing,paid,failed,cancelled,refunded) default pending | |
| gateway_transaction_id | string null | |
| gateway_reference | string null | |
| gateway_payload | json null | request/response |
| paid_at | timestamp null | |
| expires_at | timestamp null | payment window |
| failure_reason | string null | |
| metadata | json null | |
| timestamps | | index (user_id); index (status); index (payable_type, payable_id) |

#### `payment_webhooks`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | gateway, payment_id FK null, event_type null, payload json, headers json null, signature_valid bool null, processed bool default false, processed_at null, ip_address null, created_at |

### 6.2 Gateway Abstraction

```
App\Services\Payment\PaymentGateway          (interface: initiate(), verify(), handleCallback())
App\Services\Payment\ZainCashGateway         (JWT-signed transaction init → redirect → verify token)
App\Services\Payment\FibGateway              (OAuth client-credentials → create payment → poll/callback status)
App\Services\Payment\PaymentManager          (resolve gateway by enum)
```

- **ZainCash:** sign transaction with merchant secret (JWT), redirect user to ZainCash, verify the returned token, mark `paid`. Use test base URL in non-prod.
- **FIB:** obtain OAuth token (client id/secret), create payment, receive QR/redirect, confirm via callback + status check.

> Confirm exact ZainCash/FIB request/response contracts against their current onboarding docs during integration — keep the gateway classes the only place that knows provider specifics.

### 6.3 API Endpoints — Payments

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/api/v1/payments/initiate` | sanctum | Body: `payable_type`, `payable_id`, `gateway`. Creates `payment`, returns redirect/QR + `payment_number`. |
| GET | `/api/v1/payments/{number}/status` | sanctum + owner | poll status (app uses while waiting) |
| GET | `/api/v1/payments` | sanctum | user's payment history |
| POST | `/api/v1/payments/zaincash/callback` | none (signed) | ZainCash return/IPN → verify → update + log webhook |
| POST | `/api/v1/payments/fib/callback` | none (signed) | FIB callback → verify → update + log webhook |

> Callbacks live in `api.php` but are **public + signature-verified** (not `auth:sanctum`). On `paid`, fire an event that advances the related listing `pending_payment → pending_review`.

### 6.4 Admin Routes (`web.php`) — Payments

```
GET   /admin/payments                 # list/filter
GET   /admin/payments/{payment}
POST  /admin/payments/{payment}/refund        # manual/refund handling
GET   /admin/payments/webhooks                # webhook log
```

### 6.5 Acceptance Criteria

- Initiate → redirect → callback → `paid` updates payment and unlocks the listing.
- Callback signature verified; replays are idempotent (no double-processing).
- Every gateway interaction logged in `payment_webhooks`/`gateway_payload`.

---

## Phase 7 — Notifications (FCM)

**Goal:** push via FCM (no Reverb/Redis). Per-user and broadcast notifications, device-token management, admin composer, automatic match-event pushes (goals, kickoff, fulltime).

### 7.1 Database Schema

#### `app_notifications`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| user_id | FK→users null | null = system/broadcast copy |
| title_ar, title_en | string | |
| body_ar, body_en | text | |
| type | enum(general,match,goal,listing,club,fan_group,payment,system) | |
| action_type | enum(none,url,fixture,listing,club,fan_group) default none | deep link |
| action_value | string null | |
| image_path | string null | |
| data | json null | extra payload |
| is_read | bool default false | |
| read_at | timestamp null | |
| sent_at | timestamp null | |
| timestamps | | index (user_id, is_read) |

#### `notification_batches` (admin broadcasts)
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| admin_id | FK→admins | |
| title_ar, title_en | string | |
| body_ar, body_en | text | |
| target | enum(all,club_supporters,governorate,custom) | |
| target_value | json null | club id / governorate / user ids |
| type, action_type, action_value, image_path | | as above |
| total_recipients, sent_count, failed_count | int default 0 | |
| status | enum(draft,queued,sending,sent,failed) default draft | |
| scheduled_at | timestamp null | |
| sent_at | timestamp null | |
| timestamps | | |

### 7.2 Services & Jobs

- `App\Services\Notification\FcmService` — send to token / multicast via `kreait/laravel-firebase`; prune invalid tokens (mark `device_tokens.is_active=false`).
- `SendPushNotificationJob` (queued) — single user.
- `ProcessNotificationBatchJob` (queued) — resolve recipients by `target`, chunk multicast, update counters.
- **Match hooks:** `sync:live` dispatches goal/kickoff/fulltime pushes to users following that team/league (use `supported_team_id`/`supported_club_id` to target). Settings flag `notifications.match_events_enabled`.

### 7.3 API Endpoints — Notifications & Devices

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/api/v1/devices/register` | sanctum | upsert FCM token (token, platform, device info) |
| DELETE | `/api/v1/devices/unregister` | sanctum | on logout |
| GET | `/api/v1/notifications` | sanctum | paginated, `?unread=1` |
| GET | `/api/v1/notifications/unread-count` | sanctum | badge |
| POST | `/api/v1/notifications/{id}/read` | sanctum | mark read |
| POST | `/api/v1/notifications/read-all` | sanctum | mark all |

### 7.4 Admin Routes (`web.php`) — Notifications

```
GET   /admin/notifications/compose
POST  /admin/notifications/send                # create batch + dispatch job
GET   /admin/notifications/batches             # history + delivery stats
GET   /admin/notifications/batches/{batch}
```

### 7.5 Acceptance Criteria

- Token register/unregister works; invalid tokens pruned after send failures.
- Admin broadcast to "all" / club supporters / governorate reaches devices and records counts.
- Goal events during a live match trigger pushes to followers when enabled.

---

## Phase 8 — App Config & Cross-Cutting

**Goal:** glue endpoints the app needs from day one — version gate, home banners, static pages, global search, public settings.

### 8.1 Additional Schema

#### `banners`
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | |
| title_ar, title_en | string null | |
| image_path | string | |
| action_type | enum(none,url,fixture,listing,club,fan_group) default none | |
| action_value | string null | |
| placement | enum(home_top,home_middle,marketplace_top) default home_top | |
| position | int default 0 | |
| is_active | bool default true | |
| starts_at, ends_at | timestamp null | scheduling |
| timestamps | | |

#### `pages` (privacy, terms, about — also used for store compliance)
| Column | Type | Notes |
|---|---|---|
| id | bigint PK | slug unique, title_ar/en, content_ar/en longtext, is_active, timestamps |

### 8.2 API Endpoints — App

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/api/v1/app/config` | none | min/force version (by `?platform=`), public settings, feature flags |
| GET | `/api/v1/banners` | sanctum | active banners by placement |
| GET | `/api/v1/pages/{slug}` | none | static page (privacy/terms) |
| GET | `/api/v1/search` | sanctum | global: teams, players, clubs, fan groups, listings (`?q=&type=`) |
| GET | `/api/v1/governorates` | none | Iraqi governorate list (static/seeded) for dropdowns |

### 8.3 Admin Routes (`web.php`)

```
Resource /admin/banners
Resource /admin/pages
Resource /admin/settings        # (created Phase 1; manage feature flags & public settings here)
```

### 8.4 Acceptance Criteria

- `/api/v1/app/config` returns correct force-update for a given platform/version and exposes only `is_public` settings + feature flags.
- Global search returns mixed entity types in a typed, paginated shape.
- Privacy/terms pages are reachable unauthenticated (store review needs public URLs).

---

## Phase 9 — Admin Panel (Standalone Vue 3 SPA + Vue Router)

**Goal:** a standalone **Vue 3 SPA** (Vite, **Vue Router**, Pinia — **no Inertia**) that consumes the admin JSON API in `web.php`. Session/cookie auth via the `web` guard. RTL, Arabic-first.

### 9.1 Architecture

- **Frontend:** Vue 3 + **Vue Router** (history mode, base `/admin`) + Pinia + axios + Vite + Tailwind (RTL). Lives in `resources/js/admin/`. A UI kit of your choice (PrimeVue / Element Plus / shadcn-vue) for tables, forms, dialogs.
- **Serving (default = same-origin):** Vite builds the SPA into Laravel's public path; `web.php` serves it through one fallback route → `admin.blade.php`, which mounts the app. Same-origin keeps cookie auth and CSRF trivial.
  - *Alternative:* host the SPA on a separate origin/subdomain (e.g. `admin.iqs.app`). Then you lose same-origin cookies — switch to Sanctum stateful domains (`SANCTUM_STATEFUL_DOMAINS` + `/sanctum/csrf-cookie`) with CORS `supports_credentials=true`, or a dedicated admin token guard. **Recommended: same-origin.**
- **Backend:** all admin endpoints are **JSON** under `/admin/api/v1/*` in `web.php` (see the routing convention in §0.4). Controllers in `app/Http/Controllers/Admin/` return JSON (reuse the API Resources, or admin-specific resources exposing more fields).

### 9.2 Auth Flow (session, `web` guard, CSRF)

1. Browser opens any `/admin/*` path → fallback route serves `admin.blade.php` (the SPA). The `web` middleware sets the `XSRF-TOKEN` cookie.
2. axios is configured with `withCredentials: true` and a `baseURL` of `/admin/api/v1`; it auto-reads `XSRF-TOKEN` and sends it as `X-XSRF-TOKEN`.
3. Login view → `POST /admin/api/v1/login` → `Auth::guard('web')->attempt()` → session cookie set.
4. A **Vue Router global `beforeEach` guard** calls/validates `GET /admin/api/v1/me`; on `401` it redirects to the login route. Pinia `auth` store caches the admin + permissions.
5. Protected endpoints sit behind `auth:web` (+ `permission:` middleware). Logout → `POST /admin/api/v1/logout` (invalidate + regenerate session).

### 9.3 Backend Responsibilities (`web.php`)

- Admin controllers return the standard JSON envelope (or a documented admin variant — pick one, keep it consistent).
- Admin Form Requests in `app/Http/Requests/Admin/` (server-side validation is the source of truth; mirror media/field limits from earlier phases).
- spatie `permission:` middleware per route; `super-admin` bypasses via `Gate::before`.
- `activitylog` on create/update/delete for an audit trail.
- All endpoints support the table needs of the SPA: pagination, sorting, filtering, search (reuse `spatie/laravel-query-builder`).

### 9.4 Frontend Structure (`resources/js/admin/`)

```
admin/
  main.js                 # createApp, router, pinia, axios defaults (withCredentials, XSRF)
  router/index.js         # Vue Router (history, base '/admin'), route-level permission meta + beforeEach guard
  stores/                 # Pinia: auth (admin + permissions), ui, per-domain stores
  api/                    # axios service modules (matches, marketplace, clubs, ...)
  layouts/                # AuthLayout, DashboardLayout (RTL sidebar + topbar)
  views/                  # one folder per module (below)
  components/             # DataTable, MediaUploader, DynamicForm (field_schema), ConfirmDialog, ...
  composables/            # useAuth(), useCan(permission), useToast(), useLocale()
```

- **`useCan(permission)`** drives nav visibility and button gating on the client (server still enforces — client gating is UX only).
- **Axios interceptors:** attach `Accept-Language`; handle `401`→login, `403`→toast, `422`→map field errors, `429`→retry/notice.
- **RTL & i18n:** `dir="rtl"` by default; Arabic UI strings with English fallback; locale toggle persisted.

### 9.5 Modules (one view-set per phase)

| Module | Screens |
|---|---|
| Auth | Login |
| Dashboard | Counts (live matches, pending listings, payments today, new users), recent activity |
| Matches | Leagues / teams / venues / players CRUD; fixtures CRUD + **manual scoreboard**; standings editor; **sync console** (run `sync:*`, view sync logs, toggle league lock); **live match console** to update score/events for manually-scored fixtures in real time |
| Marketplace | Categories (+ `field_schema` editor, price, contact/commission mode); stores (verify/suspend); **listing review queue** (approve/reject with reason, feature); contact-leakage report |
| Clubs | Club CRUD + nested board (org chart) / staff / titles / captains / competitions / news; verification queue |
| Fan Groups | CRUD + nested media / chants / documents (limit-aware uploaders); verification queue |
| Users | Search, view, ban/unban |
| Admins & Roles | Manage admins; assign roles & permissions |
| Payments | List/filter, detail, refund, webhook log |
| Notifications | Composer (target selector: all / club supporters / governorate / custom) + batch history & delivery stats |
| Content | Banners / Pages / Settings / App Versions |

### 9.6 Acceptance Criteria

- The SPA is served at `/admin`; **Vue Router** handles client navigation in history mode; refresh/deep-link on any `/admin/*` path loads the app (fallback works) and `/admin/api/...` is never swallowed by it.
- Admin login establishes a session and CSRF-protected requests succeed; **app-user Sanctum tokens cannot reach `/admin/api/*`**, and admin sessions cannot reach `/api/v1/*`.
- Permissions hide nav and disable actions client-side **and** are enforced server-side (`403`).
- Sync console runs syncs and shows logs; live match console updates a manual fixture's score/events.
- Listing review approve/reject updates status and notifies the seller.

---

## 10. Execution Order for Claude Code

Run phases in order; each ends green (migrations + seeders + endpoints + acceptance) before the next.

1. **Phase 1 — Foundation.** Scaffold, packages, dual-guard auth, OTP, roles, devices, settings, response envelope, exception handler, localization. *Hard dependency for all.*
2. **Phase 2 — Match Sections.** Canonical store, API-Football client + sync commands + scheduler, manual entry, Resources, endpoints, admin match module. *This is the launch-critical section for the July target.*
3. **Phase 6 — Payments.** Build before marketplace publish flow needs it (or stub `manual` gateway first, wire ZainCash/FIB after).
4. **Phase 3 — Marketplace.** Categories seeder, listings lifecycle, media limits, contact/commission toggle, review queue.
5. **Phase 4 — Clubs.** Pages, org chart, archives, verification (season-flagged).
6. **Phase 5 — Fan Groups.** Archives with limits, verification (season-flagged).
7. **Phase 7 — Notifications.** FCM, device tokens, batches, match-event hooks.
8. **Phase 8 — App Config.** Version gate, banners, pages, search, governorates.
9. **Phase 9 — Admin Panel.** Standalone Vue 3 SPA + Vue Router consuming the `/admin/api/v1` JSON endpoints (can progress incrementally alongside each phase).

### Per-phase working method (for the agent)
1. Write migrations first; run `php artisan migrate:fresh --seed` to validate schema.
2. Create models + relationships + casts + factories.
3. Add PHP enums in `Support/Enums`.
4. Build services/jobs/commands (Phase 2/6/7).
5. Build API controllers + Form Requests + Resources (`Api/V1`), register in `api.php`.
6. Build admin JSON controllers + Form Requests + Resources under the `/admin/api/v1` prefix in `web.php`; add the `/admin/{any?}` SPA-shell fallback once; build the matching Vue Router views/stores in `resources/js/admin/`.
7. Add policies/permission checks.
8. Write feature tests for the acceptance criteria; run `php artisan test`.
9. Update `.env.example` with any new keys.

### Cross-cutting rules (apply everywhere)
- API controllers go **only** in `Api/V1` and routes **only** in `api.php`; admin controllers/routes **only** in `web.php`. No shared controllers.
- All app-facing list endpoints paginate and use the standard envelope.
- Every syncable table keeps `source`/`external_id`/`external_payload`/`last_synced_at`; sync upserts and never overwrites `manual`/`is_locked` rows.
- Translatable display fields are `*_ar`/`*_en`; Resources resolve by `Accept-Language` with fallback.
- Media on local disk; per-entity count limits enforced in Form Requests.
- Money in IQD by default (USD allowed); store amounts as `decimal(12,2)`.
- Queue = `database`; long tasks (sync, push, batches) are queued jobs.
- Provide `php artisan` seeders: roles/permissions, marketplace categories, governorates, a demo admin.

---

### Open Items to Confirm With Client / During Integration
- API-Football **Iraqi coverage** for Second Division, First Division, youth, juniors — anything uncovered is manual-entry only (the match console handles this).
- Final **monetization mode** (contact vs commission) — schema supports both; default to `contact` + listing fee until decided.
- **SMS provider** for OTP (Iraq-capable) — abstracted behind `OtpSender`.
- Exact **ZainCash/FIB** API contracts from their current onboarding docs.
- **Season-start** date to flip verification feature flags (clubs + fan groups).
