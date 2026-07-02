import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iqs_flutter/shared/l10n/app_localizations.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';

/// Verifies the Arabic->English i18n sweep end-to-end: the generated
/// [AppLocalizations] resolves both locales, Arabic stays byte-identical to the
/// original strings, and a real widget flips language via the delegate.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final ar = lookupAppLocalizations(const Locale('ar'));

  group('AppLocalizations', () {
    test('English and Arabic are non-empty and correct for a spread of keys',
        () {
      // A cross-section: shared vocab, nav chrome, feature screens, admin forms.
      for (final s in <String>[
        en.navHome, en.navMore, en.save, en.cancel, en.retry,
        en.homeSectionsTitle, en.matchesNavFilterAll, en.authOtpTitle,
        en.paymentStatusPaid, en.adminNameAr, en.clubsTitle,
      ]) {
        expect(s.trim(), isNotEmpty);
      }

      // Exact English values (proves no fallback-to-Arabic).
      expect(en.navHome, 'Home');
      expect(en.navMatches, 'Matches');
      expect(en.save, 'Save');
      expect(en.retry, 'Retry');

      // Arabic must stay byte-identical to the original UI strings (Rule 1).
      expect(ar.navHome, 'الرئيسية');
      expect(ar.navMatches, 'المباريات');
      expect(ar.save, 'حفظ');
      expect(ar.retry, 'إعادة المحاولة');

      // The two locales must actually differ (not both English or both Arabic).
      expect(en.navHome == ar.navHome, isFalse);
      expect(en.homeSectionsTitle == ar.homeSectionsTitle, isFalse);
    });

    test('placeholder methods interpolate their arguments in both locales', () {
      expect(en.resendIn(30), contains('30'));
      expect(ar.resendIn(30), contains('30'));
      expect(en.matchesNavSeasonLabel('2024'), contains('2024'));
      expect(ar.matchesNavSeasonLabel('2024'), contains('2024'));
      expect(en.matchSocialPredictionsCount('12'), contains('12'));
    });
  });

  testWidgets('a widget renders English under Locale(en) and Arabic under Locale(ar)',
      (tester) async {
    Widget app(Locale locale) => MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(body: Text(context.l10n.navHome)),
          ),
        );

    await tester.pumpWidget(app(const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('الرئيسية'), findsNothing);

    await tester.pumpWidget(app(const Locale('ar')));
    await tester.pumpAndSettle();
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });
}
