import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/i18n/locale_provider.dart';
import 'core/routing/app_router.dart';
import 'features/notifications/application/push_service.dart';
import 'shared/l10n/app_localizations.dart';
import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';

/// Root app widget. Builds [MaterialApp.router] from the go_router config and
/// drives locale/RTL from [localeProvider] (Arabic default → RTL).
class IqsApp extends ConsumerWidget {
  const IqsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    // Instantiate the push lifecycle so it reacts to auth (register on login).
    // It's fully guarded — a no-op until Firebase platform config is added.
    ref.watch(pushLifecycleProvider);

    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.screenBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        primary: AppColors.primaryGreen,
      ),
    );

    return MaterialApp.router(
      title: 'IQS',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(textTheme: AppText.textTheme(base.textTheme)),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    );
  }
}
