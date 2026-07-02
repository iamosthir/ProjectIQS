import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/features/auth/application/auth_providers.dart';
import 'package:iqs_flutter/features/auth/presentation/login_screen.dart';
import 'package:iqs_flutter/features/auth/presentation/otp_screen.dart';
import 'package:iqs_flutter/features/auth/presentation/register_screen.dart';
import 'package:iqs_flutter/features/auth/presentation/splash_screen.dart';
import 'package:iqs_flutter/features/auth/presentation/update_screen.dart';
import 'package:iqs_flutter/features/discovery/presentation/page_viewer_screen.dart';
import 'package:iqs_flutter/features/discovery/presentation/search_screen.dart';
import 'package:iqs_flutter/features/marketplace/presentation/listing_detail_screen.dart';
import 'package:iqs_flutter/features/marketplace/presentation/listing_form_screen.dart';
import 'package:iqs_flutter/features/marketplace/presentation/marketplace_screen.dart';
import 'package:iqs_flutter/features/marketplace/presentation/media_manager_screen.dart';
import 'package:iqs_flutter/features/marketplace/presentation/my_listings_screen.dart';
import 'package:iqs_flutter/features/marketplace/presentation/my_store_screen.dart';
import 'package:iqs_flutter/features/marketplace/presentation/store_edit_screen.dart';
import 'package:iqs_flutter/features/matches/presentation/comments_screen.dart';
import 'package:iqs_flutter/features/matches/presentation/correct_predictions_screen.dart';
import 'package:iqs_flutter/features/matches/presentation/league_detail_screen.dart';
import 'package:iqs_flutter/features/matches/presentation/leagues_screen.dart';
import 'package:iqs_flutter/features/matches/data/fixture_news.dart';
import 'package:iqs_flutter/features/matches/presentation/fixture_news_article_screen.dart';
import 'package:iqs_flutter/features/matches/presentation/match_detail_screen.dart';
import 'package:iqs_flutter/features/matches/presentation/player_detail_screen.dart';
import 'package:iqs_flutter/features/matches/presentation/replies_screen.dart';
import 'package:iqs_flutter/features/matches/presentation/team_detail_screen.dart';
import 'package:iqs_flutter/features/notifications/presentation/notifications_screen.dart';
import 'package:iqs_flutter/features/profile/presentation/edit_profile_screen.dart';
import 'package:iqs_flutter/features/payments/data/payment.dart';
import 'package:iqs_flutter/features/payments/presentation/payment_history_screen.dart';
import 'package:iqs_flutter/features/payments/presentation/payment_method_screen.dart';
import 'package:iqs_flutter/features/payments/presentation/payment_status_screen.dart';
import 'package:iqs_flutter/screens/home_screen.dart';
import 'package:iqs_flutter/screens/matches_screen.dart';
import 'package:iqs_flutter/screens/more_screen.dart';
import 'package:iqs_flutter/features/clubs/presentation/admin/my_club_content_screen.dart';
import 'package:iqs_flutter/features/clubs/presentation/admin/my_club_dashboard_screen.dart';
import 'package:iqs_flutter/features/clubs/presentation/admin/my_club_edit_screen.dart';
import 'package:iqs_flutter/features/clubs/presentation/admin/my_club_news_screen.dart';
import 'package:iqs_flutter/features/clubs/presentation/club_news_article_screen.dart';
import 'package:iqs_flutter/features/clubs/presentation/club_profile_screen.dart';
import 'package:iqs_flutter/features/clubs/presentation/clubs_directory_screen.dart';
import 'package:iqs_flutter/features/fan_groups/presentation/admin/my_fan_group_chants_screen.dart';
import 'package:iqs_flutter/features/fan_groups/presentation/admin/my_fan_group_dashboard_screen.dart';
import 'package:iqs_flutter/features/fan_groups/presentation/admin/my_fan_group_documents_screen.dart';
import 'package:iqs_flutter/features/fan_groups/presentation/admin/my_fan_group_edit_screen.dart';
import 'package:iqs_flutter/features/fan_groups/presentation/admin/my_fan_group_media_screen.dart';
import 'package:iqs_flutter/features/fan_groups/presentation/fan_group_profile_screen.dart';
import 'package:iqs_flutter/features/fan_groups/presentation/fan_groups_directory_screen.dart';
import 'package:iqs_flutter/screens/welcome_screen.dart';
import 'package:iqs_flutter/shared/data/reference_providers.dart';
import 'route_error_screen.dart';
import 'shell_scaffold.dart';

/// Bottom-nav tab routes, indexed to match the shell's nav destinations.
const List<String> kTabRoutes = ['/home', '/matches', '/news', '/video', '/more'];

/// Root navigator key — exposed so the push layer (Phase 8B) can grab a
/// navigator/overlay context for foreground banners and deep-link tap routing.
final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

/// Bridges Riverpod auth/config changes to go_router's [refreshListenable] so
/// the redirect re-runs when the session or version gate changes.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authProvider, (_, _) => notifyListeners());
    ref.listen(appConfigProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    // Unmatched locations (e.g. a deep link to a not-yet-shipped feature) show
    // a styled clay screen instead of go_router's raw error page.
    errorBuilder: (_, _) => const RouteErrorScreen(),
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // /otp requires its challenge args; a bare navigation falls back to login.
      if (loc == '/otp' && state.extra is! OtpArgs) return '/login';

      // Force-update gate — blocking, evaluated without waiting on config.
      final forced =
          ref.read(appConfigProvider).valueOrNull?.version?.forceUpdate ?? false;
      if (forced && loc != '/update') return '/update';

      final auth = ref.read(authProvider);
      // While restoring the session (or on restore error) hold on the splash —
      // but if a forced update has already pinned us to '/update', stay there.
      // (Bouncing '/update' back to '/' here would ping-pong with the gate above
      // and trip go_router's redirect-loop guard.)
      if (auth.isLoading || auth.hasError) {
        if (forced) return null;
        return loc == '/' ? null : '/';
      }

      final session = auth.requireValue;
      // The splash ('/') is transient: once auth has resolved it is never a
      // terminal location — only welcome/login/otp are. (Including '/' here was
      // the bug that left an unauthenticated cold start stuck on the spinner.)
      final isAuthScreen =
          loc == '/welcome' || loc == '/login' || loc == '/otp';
      final isPage = loc.startsWith('/page/');

      if (session.isUnauthenticated) {
        if (isAuthScreen || isPage || loc == '/update') return null;
        return '/welcome';
      }
      if (session.isNeedsRegistration) {
        if (loc == '/register' || isPage || loc == '/update') return null;
        return '/register';
      }
      // Authenticated: leave the splash / auth flow for the app.
      if (loc == '/' || isAuthScreen || loc == '/register') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/update', builder: (_, _) => const UpdateScreen()),
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/otp',
        builder: (_, state) => OtpScreen(args: state.extra as OtpArgs),
      ),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/page/:slug',
        builder: (_, state) =>
            PageViewerScreen(slug: state.pathParameters['slug']!),
      ),
      // Detail routes push above the shell (full screen, no bottom nav).
      GoRoute(
        path: '/fixtures/:id',
        builder: (_, state) => MatchDetailScreen(
          fixtureId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/fixtures/:id/comments',
        builder: (_, state) => CommentsScreen(
          fixtureId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/fixtures/:id/news/:newsId',
        builder: (_, state) => FixtureNewsArticleScreen(
          news: state.extra is FixtureNews ? state.extra as FixtureNews : null,
        ),
      ),
      GoRoute(
        path: '/fixtures/:id/predictions/correct',
        builder: (_, state) => CorrectPredictionsScreen(
          fixtureId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/comments/:id/replies',
        builder: (_, state) {
          // extra carries (fixtureId, parentContext) so a reply can be posted
          // under the parent's context.
          final extra = state.extra;
          final args = extra is (int, String) ? extra : null;
          return RepliesScreen(
            commentId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            fixtureId: args?.$1,
            parentContext: args?.$2 ?? 'match',
          );
        },
      ),
      GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
      GoRoute(
          path: '/notifications',
          builder: (_, _) => const NotificationsScreen()),
      GoRoute(
          path: '/profile/edit',
          builder: (_, _) => const EditProfileScreen()),
      GoRoute(path: '/market', builder: (_, _) => const MarketplaceScreen()),
      GoRoute(
          path: '/market/my-store', builder: (_, _) => const MyStoreScreen()),
      GoRoute(
          path: '/market/store/edit',
          builder: (_, _) => const StoreEditScreen()),
      GoRoute(
          path: '/market/my-listings',
          builder: (_, _) => const MyListingsScreen()),
      GoRoute(
          path: '/market/listings/new',
          builder: (_, _) => const ListingFormScreen()),
      GoRoute(
        path: '/market/listings/:id/edit',
        builder: (_, state) => ListingFormScreen(
          listingId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/market/listings/:id/media',
        builder: (_, state) => MediaManagerScreen(
          listingId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/listings/:id',
        builder: (_, state) => ListingDetailScreen(
          listingId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/clubs/:id',
        builder: (_, state) => ClubProfileScreen(
          clubId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/fan-groups/:id',
        builder: (_, state) => FanGroupProfileScreen(
          fanGroupId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
          path: '/my-fan-group',
          builder: (_, _) => const MyFanGroupDashboardScreen()),
      GoRoute(
          path: '/my-fan-group/edit',
          builder: (_, _) => const MyFanGroupEditScreen()),
      GoRoute(
          path: '/my-fan-group/media',
          builder: (_, _) => const MyFanGroupMediaScreen()),
      GoRoute(
          path: '/my-fan-group/chants',
          builder: (_, _) => const MyFanGroupChantsScreen()),
      GoRoute(
          path: '/my-fan-group/documents',
          builder: (_, _) => const MyFanGroupDocumentsScreen()),
      GoRoute(
        path: '/clubs/:id/news/:newsId',
        builder: (_, state) => ClubNewsArticleScreen(
          clubId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          newsId: int.tryParse(state.pathParameters['newsId'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
          path: '/my-club', builder: (_, _) => const MyClubDashboardScreen()),
      GoRoute(
          path: '/my-club/edit', builder: (_, _) => const MyClubEditScreen()),
      GoRoute(
          path: '/my-club/news', builder: (_, _) => const MyClubNewsScreen()),
      GoRoute(
        path: '/my-club/content/:type',
        builder: (_, state) =>
            MyClubContentScreen(type: state.pathParameters['type'] ?? ''),
      ),
      // Payments (Phase 7). Register the literal `/pay/status/...` before the
      // two-param `/pay/:payableType/:id` so it wins the match.
      GoRoute(path: '/payments', builder: (_, _) => const PaymentHistoryScreen()),
      GoRoute(
        path: '/pay/status/:number',
        builder: (_, state) => PaymentStatusScreen(
          paymentNumber: state.pathParameters['number'] ?? '',
          initial: state.extra is Payment ? state.extra as Payment : null,
        ),
      ),
      GoRoute(
        path: '/pay/:payableType/:id',
        builder: (_, state) => PaymentMethodScreen(
          payableType: state.pathParameters['payableType'] ?? '',
          payableId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(path: '/leagues', builder: (_, _) => const LeaguesScreen()),
      GoRoute(
        path: '/leagues/:id',
        builder: (_, state) => LeagueDetailScreen(
          leagueId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/teams/:id',
        builder: (_, state) => TeamDetailScreen(
          teamId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/players/:id',
        builder: (_, state) => PlayerDetailScreen(
          playerId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state, navigationShell) =>
            ShellScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, _) =>
                    HomeScreen(onSelectTab: (i) => context.go(kTabRoutes[i])),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/matches', builder: (_, _) => const MatchesScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/news',
                builder: (_, _) => const ClubsDirectoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/video',
                builder: (_, _) => const FanGroupsDirectoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, _) => Consumer(
                  builder: (context, ref, _) => MoreScreen(
                    onLogout: () => ref.read(authProvider.notifier).logout(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
