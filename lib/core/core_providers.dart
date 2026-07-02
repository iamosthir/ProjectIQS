import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'storage/app_prefs.dart';
import 'storage/secure_token_store.dart';

/// Bootstrapped in `main()` and injected via `ProviderScope(overrides: …)`.
final appPrefsProvider = Provider<AppPrefs>(
  (ref) => throw UnimplementedError(
    'appPrefsProvider must be overridden in main() with a bootstrapped AppPrefs',
  ),
);

/// Bootstrapped in `main()` with its cache already warmed (so interceptors can
/// read the token synchronously).
final secureTokenStoreProvider = Provider<SecureTokenStore>(
  (ref) => throw UnimplementedError(
    'secureTokenStoreProvider must be overridden in main()',
  ),
);

/// Incremented by [ApiClient] whenever a 401 is seen. The auth notifier listens
/// and drops the session to unauthenticated (the token is already cleared by
/// the time this fires).
final unauthorizedSignalProvider = StateProvider<int>((ref) => 0);
