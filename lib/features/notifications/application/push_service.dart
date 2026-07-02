import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iqs_flutter/core/config/env.dart';
import 'package:iqs_flutter/core/core_providers.dart';
import 'package:iqs_flutter/core/routing/app_router.dart';
import 'package:iqs_flutter/core/routing/deep_link.dart';
import 'package:iqs_flutter/features/auth/application/auth_providers.dart';
import 'package:iqs_flutter/features/notifications/application/notifications_providers.dart';
import 'package:iqs_flutter/features/notifications/presentation/notification_banner.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';

/// FCM background handler. MUST be a top-level/static function. We don't render
/// anything here (the OS shows the system notification); tap routing happens in
/// [PushService] via onMessageOpenedApp / getInitialMessage.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Intentionally empty — display handled by the OS, routing on tap.
}

/// Wires Firebase Cloud Messaging into the app. **Fully guarded**: if Firebase
/// isn't configured (no `google-services.json` / APNs) every call degrades to a
/// no-op, so the app runs normally with push simply dormant. Push is mobile-only
/// (skipped on web). Activates once the platform config is added.
class PushService {
  PushService(this._ref);

  final Ref _ref;

  bool _started = false;
  bool _available = false;
  String? _token;

  String get _platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  /// One-time init: Firebase + permission + message listeners. Safe to call
  /// repeatedly. No-op on web or when Firebase isn't configured.
  Future<void> start() async {
    if (_started || kIsWeb) return;
    _started = true;
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessage.listen(_onForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_onTapMessage);
      messaging.onTokenRefresh.listen(_onTokenRefresh);
      _available = true;

      // A tap that cold-started the app (terminated state).
      final initial = await messaging.getInitialMessage();
      if (initial != null) _onTapMessage(initial);
    } catch (e) {
      // No Firebase config yet → push disabled, app continues normally.
      _available = false;
      if (kDebugMode) debugPrint('Push disabled (no Firebase config): $e');
    }
  }

  /// Register the current FCM token for the logged-in user. Call after auth.
  Future<void> registerToken() async {
    if (!_available) return;
    try {
      _token = await FirebaseMessaging.instance.getToken();
      final token = _token;
      if (token == null || token.isEmpty) return;
      await _ref.read(devicesRepositoryProvider).register(
            token: token,
            platform: _platform,
            appVersion: Env.appVersion,
          );
    } catch (_) {/* best-effort */}
  }

  /// Deregister this device. Call on logout BEFORE the token is revoked, so the
  /// Bearer is still valid for the request.
  Future<void> unregisterToken() async {
    final token = _token;
    if (!_available || token == null) return;
    try {
      await _ref.read(devicesRepositoryProvider).unregister(token);
    } catch (_) {/* best-effort */}
    _token = null;
  }

  Future<void> _onTokenRefresh(String token) async {
    _token = token;
    final authed =
        _ref.read(authProvider).valueOrNull?.isAuthenticated ?? false;
    if (!authed) return;
    try {
      await _ref.read(devicesRepositoryProvider).register(
            token: token,
            platform: _platform,
            appVersion: Env.appVersion,
          );
    } catch (_) {/* best-effort */}
  }

  void _onForeground(RemoteMessage message) {
    _ref.invalidate(unreadCountProvider);
    // Respect the user's in-app banner preference (More → الإشعارات toggle).
    if (!_ref.read(appPrefsProvider).notificationsEnabled) return;
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    final n = message.notification;
    final data = message.data;
    final title = n?.title ?? data['title']?.toString() ?? ctx.l10n.notifDefaultTitle;
    final body = n?.body ?? data['body']?.toString() ?? '';
    showNotificationBanner(
      ctx,
      title: title,
      body: body,
      type: data['type']?.toString() ?? 'general',
      deepLink: _deepLinkOf(message),
    );
  }

  void _onTapMessage(RemoteMessage message) {
    _ref.invalidate(unreadCountProvider);
    final ctx = rootNavigatorKey.currentContext;
    final link = _deepLinkOf(message);
    if (ctx != null && ctx.mounted && link.isActionable) {
      handleDeepLink(ctx, link);
    }
  }

  DeepLink _deepLinkOf(RemoteMessage message) {
    final data = message.data;
    return DeepLink(
      actionType: (data['action_type'] ?? 'none').toString(),
      actionValue: data['action_value']?.toString(),
    );
  }
}

/// Owns the [PushService]. Deliberately has NO dependencies so that
/// [AuthNotifier.logout] can `ref.read` it (to unregister the device before the
/// token is revoked) without forming a cycle. The auth-driven lifecycle lives in
/// [pushLifecycleProvider] instead.
final pushServiceProvider =
    Provider<PushService>((ref) => PushService(ref));

/// Drives the push lifecycle from auth transitions. Kept SEPARATE from
/// [pushServiceProvider] to avoid a circular dependency: `authProvider` →
/// `pushServiceProvider` (via logout) must not loop back, so the listener that
/// depends on `authProvider` lives here — read only by the app root, never by
/// `authProvider`. Instantiate it once by watching it at the app root.
final pushLifecycleProvider = Provider<void>((ref) {
  final service = ref.watch(pushServiceProvider);
  ref.listen(
    authProvider,
    (prev, next) {
      final wasAuth = prev?.valueOrNull?.isAuthenticated ?? false;
      final isAuth = next.valueOrNull?.isAuthenticated ?? false;
      // Reset the unread badge whenever the session flips, so a re-login (esp.
      // as a different user) never shows the previous user's cached count.
      if (isAuth != wasAuth) ref.invalidate(unreadCountProvider);
      if (isAuth && !wasAuth) {
        service.start().then((_) => service.registerToken());
      }
    },
    fireImmediately: true,
  );
});
