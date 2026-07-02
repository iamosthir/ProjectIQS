import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core_providers.dart';

/// App locale (`ar` default RTL / `en`). Persisted to prefs and read by the
/// [LocaleInterceptor] for the `Accept-Language` header. Phase 9 additionally
/// pushes the choice to `PUT /auth/profile {locale}`.
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final code = ref.read(appPrefsProvider).localeCode;
    return Locale(code ?? 'ar');
  }

  Future<void> setLocale(String code) async {
    if (code != 'ar' && code != 'en') return;
    await ref.read(appPrefsProvider).setLocaleCode(code);
    state = Locale(code);
  }

  Future<void> toggle() =>
      setLocale(state.languageCode == 'ar' ? 'en' : 'ar');
}

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);
