import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/core_providers.dart';
import 'core/storage/app_prefs.dart';
import 'core/storage/secure_token_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bootstrap the synchronous-access singletons before the first frame so the
  // auth interceptor can read the token and the locale is known immediately.
  final prefs = await AppPrefs.create();
  final tokenStore = SecureTokenStore();
  await tokenStore.read(); // warm the in-memory token cache

  runApp(
    ProviderScope(
      overrides: [
        appPrefsProvider.overrideWithValue(prefs),
        secureTokenStoreProvider.overrideWithValue(tokenStore),
      ],
      child: const IqsApp(),
    ),
  );
}
