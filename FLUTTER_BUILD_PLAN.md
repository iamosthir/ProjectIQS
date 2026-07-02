# IQS Flutter App — Build & Integration Plan

> **App:** `iqs_flutter` (Iraqi Sports Super-App) · **Backend:** Laravel 12 mobile API at `IQSLaravel/` (`/api/v1/*`, Sanctum token auth, all 9 backend phases complete & seeded).
> **Goal:** Take the existing Claymorphism **UI skin** (Arabic/RTL, 5 designed screens) and grow it into a complete, production app wired to every backend endpoint, covering **all four roles** (plain user, seller, club-admin, group-admin).
> **Decisions (locked):** State/Net/Routing = **Riverpod + Dio + go_router**. Localization = **Arabic (default, RTL) + English (toggle)**, driven by the `Accept-Language` header.

---

## 0. Current state (what exists vs. what's missing)

**Exists (presentation only):** A well-factored Claymorphism design system — `lib/theme/` (`AppColors`, `AppText`, `Clay`) extracted verbatim from `ui/*.dc.html` mockups — and a reusable clay widget kit (`ClayCard`, `Clay3DButton`, `ClayOutlineButton`, `ClayHeaderButton`, `ClaySocialButton`, `ClayCircleBadge`, `ClaySectionTile`, `ClayToggle`, `AppHeader`, `BottomNavBar`, `SettingsIconTile`, `NetworkImageBox`, `Pressable`). *(The Welcome screen leans on `ClayOutlineButton`/`ClaySocialButton`/`ClayCircleBadge` — reuse, don't re-implement.)* Five screens: `WelcomeScreen` (onboarding), `MainScaffold` (5-tab `IndexedStack`), `HomeScreen`, `MatchesScreen`, `NewsScreen` (actually a **club-profile** screen), `MoreScreen`, plus a `VideoScreen` placeholder.

**Missing (everything below the UI):** No HTTP client, no state management, no routing package, no real auth/token storage, no domain models or JSON (de)serialization, no i18n catalog (Arabic strings are hardcoded inline), no error/loading/empty/retry/pagination patterns, no dark theme (the More toggle is decorative), no tests. All screen content is hardcoded `TODO(content)` lists. **The app and backend are currently unconnected.**

**Implication:** Phase 1 is not just "auth" — it must lay the entire data/state/routing/i18n foundation. That foundation is specified below and bundled into Phase 1.

### Backend contract recap (applies to every phase)

| Concern | Contract |
|---|---|
| **Base URL** | `{API_BASE}/api/v1/...` (configurable per flavor; local dev `http://10.0.2.2:8000` on Android emulator, `http://localhost:8000` iOS sim, LAN IP on device). |
| **Success envelope** | `{ "success": true, "message": string, "data": <payload>, "meta"?: {...} }` — **always unwrap `data`**. |
| **Error envelope** | `{ "success": false, "message": string, "errors"?: { field: [msg,...] } }`. `errors` present **only** on 422 validation. |
| **Pagination** | `meta.pagination = { current_page, per_page, total, last_page }` (exactly these 4 keys — **no** `links`/`next_url`). `hasMore = current_page < last_page`. `per_page` default 20, **max 50**, via `?per_page`; page via `?page`. |
| **Auth** | Sanctum **personal access token** (no expiry). Header `Authorization: Bearer <token>`. Token issued by `verify-otp`. No session/cookies. |
| **Locale** | `Accept-Language: ar|en` on **every** request. Server pre-resolves all `*_ar/*_en` to a single localized field — responses **never** contain both languages on read. **Writes** still send raw `_ar/_en` columns. |
| **Status codes** | 401 (no/invalid token → clear token, re-auth), 403 (ownership/banned/feature-off), 404 (not found / hidden), 422 (validation → map `errors` to fields), 429 (throttle → backoff, show message). |
| **Images** | All image/photo/logo/media fields are **relative storage paths** (e.g. `listings/12/x.jpg`), **not** absolute URLs. Prefix with `{STORAGE_BASE}/storage/`. |
| **Throttle** | `request-otp` 6/min, `verify-otp` 10/min, entire Match module 60/min/user. Others: global limiter only. |

> **Public vs authenticated (verified against `routes/api.php`):** the **only** unauthenticated app endpoints are `GET /app/config`, `GET /governorates`, `GET /pages/:slug` (plus the signature-verified gateway callbacks the app **never** calls). **Everything else requires the Bearer token** — *including* `GET /banners` and `GET /search`. Consequence: the **Home dashboard and global search are post-login screens** (a logged-out call 401s). Only the splash version-gate and the legal-pages viewer can run pre-auth.

### Role model (critical — it's ownership-driven, not role-middleware)

The three app roles are Spatie roles on the **sanctum** guard, but **no route uses `role:` middleware**. Authorization is enforced by **ownership** inside controllers. The app must gate UI on **data**, not on the role string alone:

| Role | How a user becomes it | App gating signal | Backend enforcement |
|---|---|---|---|
| **plain user** | default after first OTP login | always | `auth:sanctum` only |
| **seller** | self-service: first `POST /marketplace/stores` auto-assigns `seller` | `GET /marketplace/my-store` returns an object (≠ null) | store/listing `user_id == auth.id` (403 otherwise); listing create requires an existing store (422) |
| **club-admin** | **admin-granted only** (admin sets `clubs.managed_by = userId`) | `GET /my-club` returns 200 (not 403) | `User.managedClub` (HasOne via `managed_by`); 403 `"You do not manage a club."` |
| **group-admin** | **admin-granted only** (admin sets `fan_groups.managed_by = userId`) | `GET /my-fan-group` returns 200 (not 403) | `User.managedFanGroup` (HasOne); 403 `"You do not manage a fan group."` |

`user.roles: string[]` is returned by `verify-otp`/`me` and is useful for **showing entry points**, but the manage-* screens must still tolerate a 403 (probe + treat 403 as "not an admin"). A user manages **at most one** club and **one** fan group.

---

## 1. Target architecture

### 1.1 Dependencies to add (`pubspec.yaml`)

```yaml
dependencies:
  # state
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  # networking
  dio: ^5.7.0
  # routing
  go_router: ^14.6.0
  # storage / config
  flutter_secure_storage: ^9.2.2     # token (Keychain/Keystore)
  shared_preferences: ^2.3.2         # locale, onboarding flags, cached config
  # serialization
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  # i18n
  intl: ^0.19.0                      # + flutter gen-l10n (.arb)
  # push (Phase 8)
  firebase_core: ^3.8.0
  firebase_messaging: ^15.1.5
  # media / payments helpers
  cached_network_image: ^3.4.1
  url_launcher: ^6.3.1               # open gateway URLs, external links, store
  webview_flutter: ^4.10.0           # ZainCash checkout (optional; else url_launcher)
  qr_flutter: ^4.1.0                 # FIB QR (Phase 7)
  image_picker: ^1.1.2               # listing/store/club media upload
dev_dependencies:
  build_runner: ^2.4.13
  riverpod_generator: ^2.6.3
  freezed: ^2.5.7
  json_serializable: ^6.9.0
```
> **Bundle the Tajawal font** (weights 400/500/700/800/900) into `assets/fonts/` and declare it in `pubspec.yaml` instead of fetching via `google_fonts` at runtime — removes the first-launch network dependency / FOUT risk. Keep `AppText` API identical (swap `GoogleFonts.tajawal*` for `TextStyle(fontFamily: 'Tajawal')`).

### 1.2 Folder structure (feature-first)

```
lib/
  main.dart                      # ProviderScope + bootstrap (flavor, Firebase opt)
  app.dart                       # MaterialApp.router, theme, locale, RTL
  core/
    config/         env.dart, flavors.dart            # API_BASE, STORAGE_BASE per flavor
    network/        dio_client.dart, interceptors/ (auth, locale, error, log)
                    api_result.dart                   # Result<T> / failure types
                    api_exception.dart                # maps envelope errors → typed
    api/            envelope.dart, paginated.dart      # {success,message,data,meta}
    storage/        secure_token_store.dart, prefs.dart
    routing/        app_router.dart, guards.dart, deep_link.dart  # action_type router
    util/           asset_url.dart (storage path → URL), date_fmt.dart, validators.dart
    error/          failure.dart, error_view.dart, retry.dart
  shared/
    theme/          app_colors.dart, app_text.dart, clay.dart      # EXISTING — keep
    widgets/        clay_* (EXISTING) + AppChip, AppScaffold, LoadingState,
                    EmptyState, ErrorState, PaginatedListView, GovernoratePicker
    l10n/           app_ar.arb, app_en.arb (+ generated)
    models/         shared DTOs (User, Governorate, Banner, SearchResult, Page,
                    AppConfig, PageMeta, Money)
  features/
    auth/           data(repo,dto) · application(providers/notifiers) · presentation(screens,widgets)
    matches/        leagues, fixtures, live, detail, predictions, comments, teams, players
    home/           home dashboard (banners + featured + news strip + sections + search entry)
    discovery/      global search, banners service, static pages viewer
    marketplace/    browse + listing detail + contact + seller(store, listings, media)
    clubs/          directory + profile + news + verify + club-admin(my-club mgmt)
    fan_groups/     directory + profile + media + chants + verify + group-admin(mgmt)
    payments/       initiate, gateway checkout, polling, history
    notifications/  inbox, badge, device token lifecycle, deep-link tap
    profile/        account view, edit profile, settings (language, delete account)
```
Each feature folder follows **data → application → presentation**. Generated `*.freezed.dart`/`*.g.dart` live next to their source.

### 1.3 Core foundation pieces

**Dio client + interceptors** (`core/network/`):
- **AuthInterceptor** — injects `Authorization: Bearer <token>` from `SecureTokenStore`; on **401** clears the token and redirects to `/welcome` (via a router refresh signal).
- **LocaleInterceptor** — injects `Accept-Language` from the locale provider on every request.
- **ErrorInterceptor** — converts non-2xx into a typed `ApiException { status, message, errors }` by parsing the error envelope; normalizes 422 `errors` map; surfaces 429 `Retry-After`.
- **LogInterceptor** — pretty logs in debug flavor only.
- `dio.options.baseUrl = '${Env.apiBase}/api/v1'`, `connectTimeout`/`receiveTimeout`, `validateStatus` to let the ErrorInterceptor handle codes.

**Envelope models** (`core/api/`):
```dart
// Every response decodes through these.
class Envelope<T> { bool success; String message; T data; PageMeta? pagination; }
class PageMeta { int currentPage, perPage, total, lastPage; bool get hasMore => currentPage < lastPage; }
```
A generic `ApiClient.get/post/put/delete<T>(path, parse: (json)=>T)` unwraps `data`, lifts `meta.pagination`, throws `ApiException` on `success:false`.

**Result + failures:** Repositories return `Future<T>` and throw typed `ApiException`; the **application layer** wraps calls in Riverpod `AsyncValue` (loading/data/error) so every screen gets uniform loading/error/retry via `ErrorState` + `LoadingState` widgets.

**AssetUrl helper:** `assetUrl(String? path) => path == null ? null : '${Env.storageBase}/storage/$path'`. Use everywhere an image/logo/media/photo/cv field is rendered (they are all relative paths).

### 1.4 Routing (go_router) & deep-links

- `MaterialApp.router` with a single `GoRouter`; `refreshListenable` tied to the **auth state** provider.
- **redirect guard:** unauthenticated → `/welcome` (except public routes: legal pages, force-update). Authenticated but `needs_registration` → `/register`. Force-update (`app/config`) → blocking `/update` route.
- **ShellRoute** for the 5-tab bottom nav (`/home`, `/matches`, `/news`, `/video`, `/more`) preserving state (replaces the manual `IndexedStack`/callback navigation). Detail routes (`/fixtures/:id`, `/clubs/:id`, `/listings/:id`, `/players/:id`, `/fan-groups/:id`, …) push above the shell.
- **Deep-link router** (`core/routing/deep_link.dart`): one function maps the **shared `action_type` + `action_value` contract** (used by **both** banners and notifications): `none`→no-op, `url`→`url_launcher`, `fixture`→`/fixtures/:id`, `listing`→`/listings/:id`, `club`→`/clubs/:id`, `fan_group`→`/fan-groups/:id`. Build it once in Phase 1; reuse in Phase 3 (banners) and Phase 8 (notifications).

### 1.5 Theme, RTL & i18n

- Keep `AppColors`/`AppText`/`Clay` as the canonical design language. Build a `ThemeData` from them (light). **Dark mode:** out of scope for MVP — wire the existing More toggle to a `themeMode` provider only once a dark palette is designed; until then hide or disable it (don't ship a dead control silently).
- **RTL:** `Directionality` follows locale (`ar`→RTL, `en`→LTR). Keep the existing "first child = right" authoring for `ar`; verify each screen mirrors correctly under `en`. Force `TextDirection.ltr` only for inert data (scores, phone numbers, dates).
- **i18n:** introduce `flutter gen-l10n` with `app_ar.arb` (primary) + `app_en.arb`. **Extract every hardcoded Arabic string** from existing screens into keys as they are wired up (do it per-screen during each phase, not big-bang). Language switch lives in Settings → updates the locale provider → (a) rebuilds UI, (b) changes the `Accept-Language` header, (c) persists to prefs **and** `PUT /auth/profile {locale}`.

---

## 2. Navigation / information architecture

The 5 mockup tabs don't map 1:1 to the backend. Proposed mapping (see **Open Decisions** for the two flagged items):

| Tab | Backend reality | Plan |
|---|---|---|
| **الرئيسية / Home** | banners + fixtures + (no global news feed) | Dashboard: banner carousel (**`GET /banners` once, no `placement` param → group client-side by the `placement` field** `home_top`/`home_middle`, order each group by `position`, tap→deep-link) → live/featured fixtures (`/fixtures/live`, `/fixtures?status_group=…`) → latest club-news strip → **4-tile sections grid** (الأخبار→Clubs, المباريات→Matches, الفيديو→Fan-Groups, **الفرق→Leagues&Teams browse**) → search entry. |
| **المباريات / Matches** | `/fixtures*`, `/leagues*` | The fixtures feed + filters (already designed). Drill into Match Detail. |
| **الأخبار / News** | **no global news endpoint**; only per-club news | **Repurpose as a "Clubs" hub:** clubs directory → club profile (the *existing* `NewsScreen` design — see Phase 5 tab reconciliation) → club news list/article. *(Decision A)* |
| **الفيديو / Video** | no video module; closest = fan-group chants (video) | **Repurpose as Fan-Groups / chants gallery**, or keep "قريباً" until a video backend exists. *(Decision B)* |
| **المزيد / More** | profile + settings + secondary sections | Profile + settings + entry points to Marketplace, Fan Groups, Notifications, Payments/history, legal pages. Role-gated tiles: "My Store" (seller), "My Club" (club-admin), "My Fan Group" (group-admin). *(Also hosts the existing "الأندية المفضلة / Favorite Clubs" row — see Decision F.)* |

Secondary sections (Marketplace, Fan Groups, Payments, Notifications) are reached from the **Home sections grid** and the **More menu**, not new bottom-nav tabs.

> **`الفرق` / Teams has no list endpoint.** There is no `GET /teams` index — teams are reachable only by id (`/teams/:id`, `/teams/:id/squad`, `/teams/:id/fixtures`), via league **standings** (each row carries a team), and via **`/search?type=team`**. So the الفرق tile routes to the **Leagues browse** (`/leagues` → standings → team profile) and/or a search-driven team finder, **not** a standalone teams directory. Team profiles open at `/fixtures`-style detail routes (`/teams/:id`).

---

## 3. Phased delivery

Each phase ends green: screens wired, models + providers + routes in place, loading/error/empty states, i18n keys for new strings, and a manual acceptance pass against the seeded demo data (demo login phone `+9647700000001`, `OTP_EXPOSE_CODE=true` returns `debug_otp`).

---

### Phase 1 — Foundation & Authentication

**Goal:** Stand up the whole app skeleton (§1) and deliver real OTP auth + onboarding + session restore.

**1A · Foundation (prerequisite):** add deps; build `core/` (Dio + 4 interceptors, envelope/pagination/ApiException, `SecureTokenStore`, prefs, `Env`/flavors, `AssetUrl`); set up `ProviderScope`, `MaterialApp.router`, go_router shell + guards + deep-link stub; bundle Tajawal; scaffold `gen-l10n`; build shared state widgets (`LoadingState`, `ErrorState`+retry, `EmptyState`, **`OfflineState`** (global no-connectivity banner — used by every `AsyncValue` screen, not deferred to P10), `PaginatedListView`, `AppChip`, `GovernoratePicker`).

> **`NetworkImageBox` reconciliation:** the existing widget has its own loading/error placeholders that overlap the new shared states. In Phase 1 **migrate it to `cached_network_image`** (already a dep) behind the same API, so image loading/error is consistent app-wide and cached.

**1B · Auth screens & flow:**

| Screen | Route | Endpoint(s) | Notes |
|---|---|---|---|
| Splash / startup gate | `/` | `GET /app/config?platform&version` (public) + `GET /auth/me` (if token) | **Always send `?platform` & `?version`** (else the flags are meaningless). Treat **both** `version == null` *and* (`update_available == false && force_update == false`) as "no gate". |
| Force/soft-update | `/update` | (uses `app/config.version`) | `force_update` ⇒ blocking; open `store_url`; show `changelog`. |
| Welcome / onboarding | `/welcome` | — | **Reuse existing `WelcomeScreen`**; wire "تسجيل الدخول"/"إنشاء حساب" → `/login`; social buttons stay "قريباً". |
| Phone entry | `/login` | `POST /auth/request-otp` | Iraq-only; send raw number (server normalizes `phone:IQ`). Handle 422 (invalid phone) and **429 resend-cooldown → read top-level `retry_after` (seconds) + `Retry-After` header to drive the "resend in Ns" countdown**. |
| OTP verify | `/otp` | `POST /auth/verify-otp` | 6-digit input; resend countdown from `expires_in` (300s); on success store `token` (secure), read `is_new`/`needs_registration`; 403 = banned. |
| Complete profile | `/register` | `POST /auth/register` + `GET /governorates` + `GET /clubs` / `GET /search?type=team` | Shown when `needs_registration`. Name, email, governorate (picker by `code`), **supported-club picker** (see ↓), **supported-team picker** (see ↓), gender, DOB. |
| Static legal viewer | `/page/:slug` | `GET /pages/:slug` (public) | privacy/terms/about; reachable pre-login + from Settings. |

> **Supported club/team pickers (cross-cutting, also used by edit-profile):** there is **no slim option-list endpoint**. Build shared `ClubPicker` (paged from `GET /clubs`, searchable) and `TeamPicker` (typeahead via `GET /search?type=team`, since teams have no index) widgets in `shared/widgets/` alongside `GovernoratePicker`. `supported_club_id` and `supported_team_id` are distinct single selections.

**Models:** `User` (id, phone, name, email, avatar, governorate, gender, dob, locale, supportedClubId, supportedTeamId, phoneVerified, **isRegistrationCompleted ← map snake_case `is_registration_completed`**, roles[], createdAt), `AppConfig` (version{latest,minSupported,updateAvailable,forceUpdate,storeUrl,changelog}?, settings: Map), `Governorate` (code, name), `Page` (slug,title,content,updatedAt).
> **DTO naming:** the User resource field is `is_registration_completed`; `verify-otp` *also* returns a **separate top-level `needs_registration`** flag in `data` (≠ the user object). Map both; don't collapse them into one camelCase guess. Likewise `is_new` is top-level on verify-otp.

**State:** `authProvider` (AsyncNotifier: `unauthenticated | needsRegistration | authenticated(User)`); `appConfigProvider`; `localeProvider`. Token persisted in Keychain/Keystore; `me` on resume restores session.

**Acceptance:** cold start → version gate → OTP login with `debug_otp` → token persisted → app restart stays logged in → logout clears token → 401 anywhere bounces to `/welcome`. Force-update blocks. Locale header present on all calls.

---

### Phase 2 — Matches (Leagues, Fixtures, Live, Detail, Social)

**Goal:** Replace `matches_screen.dart` hardcoded `_Match` lists with the live fixtures feed and build the full match experience. *(Large — may split 2A core / 2B social.)*

**2A · Core (Leagues/Fixtures/Live/Detail):**

| Screen | Route | Endpoint(s) | Notes |
|---|---|---|---|
| Matches feed | `/matches` | `GET /fixtures?date&league&team&status_group` (paginated) | Reuse the designed filter chips → map الكل/اليوم/غداً/انتهت to `status_group`/`date`. Infinite scroll via `meta.pagination`. **Reuse `_buildMatchCard` design.** |
| Live tab/scoreboard | `/matches/live` | `GET /fixtures/live` (array) | Poll every ~60s (`services.api_football.live_poll_seconds`) while visible; stop off-screen; respect 429. |
| Leagues & Teams browse | `/leagues` | `GET /leagues?is_iraqi` (array) | `requires_auth` per league; `current_season`. **This is also the الفرق/Teams entry point** (no `/teams` index exists → reach teams via standings rows or `/search?type=team`). |
| League detail | `/leagues/:id` | `GET /leagues/:id`, `/standings?season`, `/fixtures`, `/top-scorers` | Tabs: Standings (group headers only when `group` non-null; form badges), Fixtures (paginated), Top Scorers. **`?season` = season YEAR (integer, e.g. 2025), matched against `Season.year` — NOT a season id**; omit to default to current season. |
| Match detail | `/fixtures/:id` | `GET /fixtures/:id` (full detail) | Header score/status/`elapsed`; enable tabs from `has.{events,lineups,statistics}`. Includes `social.liked_by_me`, `prediction` summary + `my_prediction`. |
| ↳ Events tab | (same) | `GET /fixtures/:id/events` | Timeline (goal/card/subst), `elapsed+extra`, player/assist. |
| ↳ Lineups tab | (same) | `GET /fixtures/:id/lineups` | Pitch via `grid` "row:col"; startXI + subs; formation; coach. |
| ↳ Stats tab | (same) | `GET /fixtures/:id/statistics` | Comparison bars from `value_numeric`, label from `value`. |
| ↳ Broadcasts | (same) | `GET /fixtures/:id/broadcasts` | Where-to-watch; `stream_url` optional. |
| Like / Share | (cards + detail) | `POST/DELETE /fixtures/:id/like`, `POST /fixtures/:id/share` | `liked_by_me` only on **detail** (not list) — track optimistic state client-side. |

**2B · Social (Predictions, Comments, Teams, Players):**

| Screen | Route | Endpoint(s) | Notes |
|---|---|---|---|
| Predictions tab | `/fixtures/:id` (tab) | `GET /fixtures/:id/predictions/summary`; `POST /fixtures/:id/predictions` | Vote-share bars + counts; `is_open` only when `scheduled`; upsert per user; 422 "closed" after kickoff. Scores 0–99. |
| Correct predictions | `/fixtures/:id/predictions/correct` | `GET .../predictions/correct` (paginated) | Per-row user + `POST/DELETE /predictions/:id/like`. |
| Comments feed | `/fixtures/:id/comments` | `GET/POST /fixtures/:id/comments` | `context` toggle (match/prediction), `sort` (newest/oldest/most_liked/most_replied), like, reply; `replies` lazy (`replies_count` → fetch). |
| Replies thread | `/comments/:id/replies` | `GET /comments/:id/replies` (paginated) | oldest-first. |
| Edit/delete comment | (inline) | `PUT/DELETE /comments/:id` | owner-only (403 otherwise). Body ≤2000. |
| Team profile | `/teams/:id` | `GET /teams/:id`, `/fixtures`, `/squad` | Profile + venue; fixtures (paginated, `status_group`); squad (sorted by `number`). |
| Player profile | `/players/:id` | `GET /players/:id` | Photo, position, DOB, nationality, height/weight, injury. |

**Models:** `Fixture` (+ `FixtureDetail`), `League`, `Season`, `Standing`, `TopScorer`, `FixtureEvent`, `Lineup`+`LineupPlayer`, `Statistic`, `Broadcast`, `Prediction`, `Comment`, `Team`, `Venue`, `Player`. Enums: `StatusGroup {scheduled,live,finished,postponed,cancelled}`, `PredictionOutcome {home,draw,away}`, `CommentContext {match,prediction}`.

**Acceptance:** feed paginates & filters; live polls and updates; detail tabs gated by `has.*`; predict→re-predict upserts; comment+reply+like; like/share reflect counts; team/player drill-down from fixtures.

---

### Phase 3 — Home, Discovery & Deep-links

**Goal:** Make the **Home** tab real and ship global search + banners + the shared deep-link router.

| Screen | Route | Endpoint(s) | Notes |
|---|---|---|---|
| Home dashboard | `/home` | `GET /banners` (no `placement`), `GET /fixtures/live` + `?status_group=scheduled`, club-news strip (Decision A) | **Reuse existing `HomeScreen`** (all calls are post-login). Slider→banner carousel: **fetch `/banners` once, group the response by its `placement` field** (`home_top`/`home_middle`), order each group by `position`, tap→deep-link. **Do not pass `?placement=home_top,home_middle`** — the backend does single-value equality, so a CSV returns an empty carousel. Sections grid→routes (incl. الفرق→Leagues), "أحدث الأخبار"→news strip. |
| Global search | `/search` | `GET /search?q&type` | Debounced `q≥2`; type chips (team/player/club/fan_group/listing); each type capped 8; route by `type`+`id`. |
| Governorate picker | (shared widget) | `GET /governorates` | Reused across register/listings/filters; cache in prefs. |
| Static pages | `/page/:slug` | `GET /pages/:slug` | (built in P1; surfaced in More/Settings). |

**Deep-link router** finalized here and reused by notifications (P8). **Models:** `Banner`, `SearchResult{type,id,title,subtitle,image}`.

**Acceptance:** Home shows live banners + fixtures; banner tap deep-links; search returns typed results and routes correctly; governorate picker reused.

---

### Phase 4 — Marketplace + **Seller** role

**Goal:** Consumer browse/contact + full seller store & listing management. *(Paid listings depend on Phase 7 Payments — ship free-category flow first.)*

**Consumer:**

| Screen | Route | Endpoint(s) | Notes |
|---|---|---|---|
| Categories | `/market` | `GET /marketplace/categories` (tree) | Root + children; `field_schema` drives dynamic forms later. |
| Listings browse | `/market/listings` | `GET /marketplace/listings?category&governorate&featured&q` (paginated) | Featured-first; search; `marketplace_top` banner strip. |
| Listing detail | `/listings/:id` | `GET /marketplace/listings/:id` | Increments views server-side (fetch once). Owner sees extra `contact`/`show_contact`/`rejection_reason`. |
| Contact action | (sheet) | `POST /marketplace/listings/:id/contact` | Render from returned `available` flag — may be `{available:false}` ("proceed through platform"). |

**Seller (gated on `my-store` ≠ null):**

| Screen | Route | Endpoint(s) | Notes |
|---|---|---|---|
| My Store | `/market/my-store` | `GET /marketplace/my-store` | null ⇒ show "Create Store" CTA. |
| Create/Edit Store | `/market/store/edit` | `POST/PUT /marketplace/stores[/:id]` | First create auto-assigns `seller`; 2nd create 422. Update owner-only (403). |
| My Listings | `/market/my-listings` | `GET /marketplace/my-listings` (paginated, all statuses) | Status chips (draft/pending_payment/pending_review/published/rejected/expired/suspended); show `rejection_reason`. |
| Create Listing | `/market/listings/new` | `POST /marketplace/listings` | Requires store (422 else). **Dynamic attributes form from `category.field_schema`**; free→`pending_review`, paid→`pending_payment` (→ Phase 7). |
| Edit Listing | `/market/listings/:id/edit` | `PUT /marketplace/listings/:id` | Editing a published/rejected/expired listing re-enters `pending_review`. |
| Media manager | `/market/listings/:id/media` | `POST /marketplace/listings/:id/media` (multipart `file`) + `DELETE` | Per-type limits (422 when full); `image_picker`; reorder by `display_order`. |

**Models:** `MarketplaceCategory` (+ `field_schema`), `Listing`, `ListingMedia`, `Store`. Enums: `ListingStatus`, `StoreStatus`, `MediaType`.

**Acceptance:** browse/filter/search; contact respects reveal gating; create store→becomes seller→create free listing→appears in My Listings as `pending_review`; edit re-moderates; media upload + limit error.

---

### Phase 5 — Clubs + **Club-admin** role (also powers the "News" tab)

**Consumer:**

| Screen | Route | Endpoint(s) | Notes |
|---|---|---|---|
| Clubs directory | `/news` (tab) or `/clubs` | `GET /clubs?q&governorate` (paginated) | Verified-first. *(Decision A: this is the "الأخبار" tab.)* |
| Club profile | `/clubs/:id` | `GET /clubs/:id` (detail) | **Reuse the `NewsScreen` *chrome*** (gradient header, crest, info card, tab strip styling) — see tab reconciliation ↓. |
| Club news list | `/clubs/:id/news` | `GET /clubs/:id/news` (paginated) | Cover+title+excerpt+author+views. |
| Club news article | `/clubs/:id/news/:newsId` | `GET /clubs/:id/news/:newsId` | Full `content`; increments views. |
| Verify/claim | (sheet) | `POST /clubs/:id/verify-request` | method message/voice/video + note; 403 when feature flag off. |

> **Club-profile tab reconciliation (the designed `NewsScreen` ships a *different* tab set than the backend's club detail).** The mockup's strip is **نظرة عامة / الأخبار / المباريات / اللاعبون / الإحصائيات** (Overview / News / Matches / Players / Statistics). Map each to data — note that a Club has no fixtures/squad of its own; those belong to its linked **Team** (`club.team_id` on `ClubResource`):
> - **نظرة عامة / Overview** → `GET /clubs/:id` — render `description`, location, contact/social, **and the org-chart sub-sections** Board (`parent_id`), Staff (by `type`), Titles, Captains, Competitions as collapsible blocks within Overview.
> - **الأخبار / News** → `GET /clubs/:id/news` (+ article).
> - **المباريات / Matches**, **اللاعبون / Players**, **الإحصائيات / Statistics** → require `club.team_id`: `GET /teams/:teamId/fixtures`, `GET /teams/:teamId/squad`, and the team's league standings/top-scorers. **If `team_id` is null, hide these three tabs.**
>
> *(If you prefer the simpler path: keep only Overview + News and drop the team-derived tabs until clubs are reliably linked to teams.)*

**Club-admin (gated on `my-club` 200):**

| Screen | Route | Endpoint(s) | Notes |
|---|---|---|---|
| My Club dashboard | `/my-club` | `GET /my-club` | 403 ⇒ not an admin (hide entry). |
| Edit profile | `/my-club/edit` | `PUT /my-club` | Send **raw `_ar/_en`** columns + location/contact/social. |
| News manager | `/my-club/news` | `POST/PUT/DELETE /my-club/news[/:id]` | **Write responses return raw model JSON** (snake_case, both langs) — normalize/refetch. |
| Content managers | `/my-club/:type` | `POST/PUT/DELETE /my-club/{type}[/:id]` | `{type}` ∈ board/staff/titles/captains/competitions; per-type bilingual forms. |

**Models:** `Club` (+ `ClubDetail` with board/staff/titles/captains/competitions), `ClubNews`. Note the **read (Resource, localized) vs write (raw `_ar/_en`) asymmetry** — use separate request DTOs.

**Acceptance:** directory→profile→news article (views increment); verify-request (or feature-off 403); club-admin edits profile, CRUDs news + each child type; non-admin gets 403 and no entry point.

---

### Phase 6 — Fan Groups + **Group-admin** role (optionally the "Video" tab)

**Consumer:**

| Screen | Route | Endpoint(s) | Notes |
|---|---|---|---|
| Fan-groups directory | `/fan-groups` (or `/video` tab — Decision B) | `GET /fan-groups?club&governorate&q` (paginated) | Official-first; official/verified badges. |
| Fan-group profile | `/fan-groups/:id` | `GET /fan-groups/:id` (detail) | `counts{photos,videos,chants}`, contact/social, documents. |
| Media gallery | `/fan-groups/:id/media` | `GET /fan-groups/:id/media?type` (paginated) | photos/videos tabs. |
| Chants | `/fan-groups/:id/chants` | `GET /fan-groups/:id/chants` (array) | video + thumbnail + lyrics. |
| Verify | (sheet) | `POST /fan-groups/:id/verify-request` | method + note; 403 when feature flag off. |

**Group-admin (gated on `my-fan-group` 200):**

| Screen | Route | Endpoint(s) | Notes |
|---|---|---|---|
| My Fan Group | `/my-fan-group` | `GET /my-fan-group` | 403 ⇒ not an admin. |
| Edit profile | `/my-fan-group/edit` | `PUT /my-fan-group` | Raw `_ar/_en` + `*_path` write names (differ from read names). |
| Manage media | `/my-fan-group/media` | `POST/DELETE /my-fan-group/media[/:id]` | Limits: 100 images / 30 videos (422 when full). |
| Manage chants | `/my-fan-group/chants` | `POST/DELETE /my-fan-group/chants[/:id]` | Limit 20 (422). |
| Manage documents | `/my-fan-group/documents` | `POST/DELETE /my-fan-group/documents[/:id]` | Create returns raw model (differs from detail's `documents[]`). |

**Models:** `FanGroup` (+ `FanGroupDetail`), `FanGroupMedia`, `FanGroupChant`, `FanGroupDocument`. **Heads-up:** read field names (`group_logo`, `url`, `video`) differ from write names (`group_logo_path`, `path`, `video_path`).

**Acceptance:** directory→profile→media/chants; verify-request; group-admin edits profile, adds/deletes media/chants/documents incl. archive-full 422s.

---

### Phase 7 — Payments (unblocks paid marketplace listings)

**Goal:** Gateway payment flow for paid-category listings (the only wired payable today; `payable_type` should be sourced from the server, not hardcoded).

| Screen | Route | Endpoint(s) | Notes |
|---|---|---|---|
| Method picker | `/pay/:payableType/:id` | — | ZainCash or FIB. |
| Initiate + checkout | (same) | `POST /payments/initiate {payable_type,payable_id,gateway}` | Server derives amount/currency. **Capture transient `redirect_url`/`qr` now** (null afterwards). ZainCash→WebView/browser; FIB→QR (`qr_flutter`) + "Open FIB app" (`redirect_url` deep link). |
| Processing/polling | `/pay/status/:number` | `GET /payments/:number/status` | Poll every 3–5s until final (`paid|failed|cancelled|refunded`); countdown to `expires_at`; persist `payment_number`. |
| Success / Failed-Expired | (same) | — | On `paid` → listing now `pending_review`. |
| Payment history | `/payments` | `GET /payments` (paginated) | number, amount, gateway, status tag. |

**Models:** `Payment` (paymentNumber, gateway, amount, currency, status, payable{type,id}, redirectUrl?, qr?, paidAt?, expiresAt). Enums: `PaymentStatus`, `Gateway {zaincash,fib}` (never send `manual`). **Error codes differ by endpoint:** `initiate` → 404 unknown payable / **403 not owner** / 502 gateway init failed; **`/:number/status` → 404** for an unknown *or* non-owned `payment_number` (user-scoped `firstOrFail`, **not 403**) — handle 404 in the polling state machine. **App never calls `/callback`** — outcome learned only by polling.

**Acceptance:** initiate paid listing → open gateway → poll → `paid` → listing advances; expiry UX; history lists past payments.

---

### Phase 8 — Notifications & Devices (FCM)

**Goal:** Push + in-app inbox + badge, with deep-link tap routing (reuses P3 router).

| Screen | Route | Endpoint(s) | Notes |
|---|---|---|---|
| Inbox | `/notifications` | `GET /notifications?unread` (paginated) | newest-first; unread highlight; pull-to-refresh; "mark all read". |
| Badge | (app bar/nav) | `GET /notifications/unread-count` | refresh on inbox open + FCM data message. |
| Mark read | (inline/tap) | `POST /notifications/:id/read`, `POST /notifications/read-all` | single is owner-checked (403). |
| Permission prompt | (system) | — | `firebase_messaging` permission; settings handoff if denied. |

**Device lifecycle:** on login/start get FCM token → `POST /devices/register {token,platform,device_*,app_version}`; on `onTokenRefresh` re-register; on logout `DELETE /devices/unregister {token}` (**JSON body** on DELETE → set Dio `data:`, not query). Foreground messages → in-app banner; tap (foreground/background/terminated) → deep-link router using `action_type`/`action_value`. `type` field is for **iconography only**, not routing.

> **Foreground in-app banner:** build one shared clay-kit widget (a `ClayCard`-based top toast with icon-by-`type`, title/body, tap→deep-link) shown via an overlay/`ScaffoldMessenger` when an FCM message arrives while the app is foregrounded. Spec it here so it isn't ad-hoc per screen.

**Models:** `AppNotification` (title,body,type,actionType,actionValue,image,data,isRead,createdAt). **Setup:** add `firebase_core`/`firebase_messaging`, `google-services.json` / `GoogleService-Info.plist`, Android notification channel, iOS APNs.

**Acceptance:** token registers; push received in all 3 states; tap deep-links; badge + inbox + mark-read/all; unregister on logout.

---

### Phase 9 — Profile, Settings & i18n completion

| Screen | Route | Endpoint(s) | Notes |
|---|---|---|---|
| Profile/account | `/more` | `GET /auth/me` | **Reuse `MoreScreen`**; show real user; role-gated tiles (My Store/Club/Fan Group). **Reconcile the existing "الأندية المفضلة / Favorite Clubs" row (count pill "3") — see Decision F.** |
| Edit profile | `/profile/edit` | `PUT /auth/profile` + `ClubPicker`/`TeamPicker` | name/email/avatar/governorate/gender/dob/**supported club & team** (reuse the shared pickers from Phase 1B). `avatar` is a URL/path string (upload via a media path, not multipart here). |
| Settings | `/settings` | `PUT /auth/profile {locale}` | **Language toggle ar/en** → flips locale provider + header + persists. Notifications toggle (ties to P8 permission). Legal pages. About (`app/config`). |
| Delete account | `/settings/delete` | `DELETE /auth/account` | confirm → clear token → `/welcome`. |
| Logout | (More) | `POST /auth/logout` | revoke current token + unregister device. |

**Also in P9:** finish extracting any remaining hardcoded strings into `.arb`; verify full RTL/LTR parity under `en`; wire the language switch end-to-end.

---

### Phase 10 — Hardening & release

Tests (unit for repos/mappers, widget for key screens, golden for clay components), global error/offline handling + retry, image caching, skeleton loaders, analytics/crash reporting, app icons/splash, store metadata, build flavors (dev/staging/prod), and the production SMS/OTP path (no `debug_otp`).

---

## 4. Coverage matrices

### 4.1 Screen → phase → endpoint (every backend endpoint is consumed)

| Backend area | Endpoints | Phase |
|---|---|---|
| App startup / config | `GET app/config`, `governorates`, `pages/:slug` | 1, 3 |
| Auth/profile | `request-otp`, `verify-otp`, `register`, `me`, `profile`, `logout`, `account` | 1, 9 |
| Leagues/standings/scorers | `leagues`, `leagues/:id[/standings,/fixtures,/top-scorers]` | 2 |
| Fixtures | `fixtures`, `fixtures/live`, `fixtures/:id[/events,/lineups,/statistics,/broadcasts]`, like/share | 2 |
| Predictions | `predictions/summary`, `/correct`, `POST predictions`, `predictions/:id/like` | 2 |
| Comments | `fixtures/:id/comments`, `comments/:id[/replies,/like]`, PUT/DELETE | 2 |
| Teams/players | `teams/:id[/fixtures,/squad]`, `players/:id` | 2 |
| Banners/search | `banners`, `search` | 3 |
| Marketplace | `categories`, `listings[/:id,/contact]`, `my-store`, `stores`, `my-listings`, `listings` CRUD, `media` | 4 |
| Clubs | `clubs[/:id,/news,/news/:id,/verify-request]`, `my-club[*]` | 5 |
| Fan groups | `fan-groups[/:id,/media,/chants,/verify-request]`, `my-fan-group[*]` | 6 |
| Payments | `payments`, `payments/initiate`, `payments/:number/status` | 7 |
| Devices/notifications | `devices/register`, `unregister`, `notifications[*]` | 8 |

### 4.2 Role → screens

- **Plain user:** all consumer browse/detail/search + auth/profile/settings/notifications + initiate payments for own payables.
- **Seller:** + My Store, Create/Edit Store, My Listings, Create/Edit Listing, Media manager (gate: `my-store ≠ null`).
- **Club-admin:** + My Club dashboard/edit, News manager, Board/Staff/Titles/Captains/Competitions managers (gate: `my-club` 200).
- **Group-admin:** + My Fan Group dashboard/edit, Media/Chants/Documents managers (gate: `my-fan-group` 200).
- A single user may be **several roles at once** (e.g. seller + group-admin) — surface each entry point independently from its own probe. `user.roles[]` is on the **sanctum** guard so the three app roles appear there reliably (good for *showing* entry tiles), but the manage-* screens are still gated by the live 200-vs-403 probe / `my-store ≠ null` — never assume `roles[]` alone grants access (club/group-admin enforcement is the `managed_by` FK, independent of the role string).

---

## 5. Open decisions (confirm before/at the relevant phase)

- **A — "الأخبار" (News) tab:** No global news feed exists in the backend (only per-club news). Recommend the tab becomes a **Clubs directory → club profile → club news** hub (reuses the existing `NewsScreen` design). Alternative: add a backend `GET /api/v1/news` aggregating published club news (small Laravel addition) if you want a true cross-club feed. *Default: Clubs hub.*
- **B — "الفيديو" (Video) tab:** No video backend. Recommend mapping it to **Fan-Groups (chants/videos)**, or keep the "قريباً" placeholder until a video module exists. *Default: Fan-Groups/chants.*
- **C — Dark mode:** the More toggle is currently decorative. Ship MVP light-only and **hide/disable** the toggle, or invest in a dark clay palette now. *Default: hide until designed.*
- **D — Payments ordering:** Marketplace paid-category listings need Phase 7. Recommend shipping Phase 4 with **free categories first** and folding Payments in immediately after (or merging P7 into P4). *Default: P4 free-first, then P7.*
- **E — Tajawal font:** bundle locally (recommended) vs keep runtime `google_fonts`. *Default: bundle.*
- **F — "الأندية المفضلة / Favorite Clubs" (More screen):** the mockup/`MoreScreen` renders a Favorite-Clubs row with a **"3" count pill**, but the backend only stores a **single** `supported_club_id` (no multi-favorites, no `/favorites` endpoint). Options: **(1, default)** collapse the row to the single supported club (drop/replace the count pill — it's decorative) and route it to the supported-club's profile; **(2)** treat multi-favorites as a **backend gap** — add a `favorites` table + `GET/POST/DELETE /api/v1/me/favorite-clubs` and a Favorites picker/list screen. As written the row currently routes nowhere and has no data source — pick one before Phase 9.
- **G — `الفرق` / Teams entry:** there is no `GET /teams` index, so the Home الفرق tile routes to **Leagues→standings→team** and/or `/search?type=team` (Default). If a flat teams directory is wanted, add a backend `GET /api/v1/teams` index.

---

## 6. Conventions checklist (every screen)

- Read through the `core` `ApiClient`; never touch Dio directly in widgets.
- Wrap data in Riverpod `AsyncValue`; render `LoadingState`/`ErrorState`(with retry)/`EmptyState`.
- Paginated lists use the shared `PaginatedListView` (reads `meta.pagination`, `hasMore`).
- Prefix every image path with `assetUrl(...)`.
- Send `Accept-Language` (automatic via interceptor); on **write**, send raw `_ar/_en` where the endpoint expects them.
- Map 422 `errors` onto form fields; show `message` for business 422/403/404; back off on 429.
- New user-facing strings go into **both** `app_ar.arb` and `app_en.arb` — never hardcode.
- Reuse the clay kit (`ClayCard`, `Clay3DButton`, `AppHeader`, chips, …); extract the duplicated chip pattern into a shared `AppChip`.
- Gate role UI by **probing the manage-* endpoint** (200 vs 403), not by the role string alone.

---

**Reference:** exact per-endpoint request/response field shapes for all 9 modules are captured in the research run that produced this plan; this document is the canonical build sequence. The backend is feature-complete and seeded (admin `admin@iqs.app` / `password`; Flutter demo login `+9647700000001`).
