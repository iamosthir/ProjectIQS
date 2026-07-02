import 'package:flutter_test/flutter_test.dart';

import 'package:iqs_flutter/core/util/asset_url.dart';
import 'package:iqs_flutter/core/util/validators.dart';
import 'package:iqs_flutter/shared/models/app_config.dart';
import 'package:iqs_flutter/shared/models/user.dart';

void main() {
  test('Validators.isIraqiPhone accepts local & international forms', () {
    expect(Validators.isIraqiPhone('07700000001'), isTrue);
    expect(Validators.isIraqiPhone('+9647700000001'), isTrue);
    expect(Validators.isIraqiPhone('7700000001'), isTrue);
    expect(Validators.isIraqiPhone('12345'), isFalse);
  });

  test('normalizeIraqiPhone canonicalizes every entry form, never doubling +964',
      () {
    const want = '+9647700000001';
    // National, with/without trunk zero.
    expect(Validators.normalizeIraqiPhone('7700000001'), want);
    expect(Validators.normalizeIraqiPhone('07700000001'), want);
    // The bug: user already typed the country code → must NOT become +964+964…
    expect(Validators.normalizeIraqiPhone('+9647700000001'), want);
    expect(Validators.normalizeIraqiPhone('9647700000001'), want);
    expect(Validators.normalizeIraqiPhone('009647700000001'), want);
    // Country code AND a national trunk zero together.
    expect(Validators.normalizeIraqiPhone('+96407700000001'), want);
    // Stray spaces / formatting are tolerated.
    expect(Validators.normalizeIraqiPhone('+964 770 000 0001'), want);
  });

  test('assetUrl builds storage URLs and passes through absolute URLs', () {
    expect(assetUrl(null), isNull);
    expect(assetUrl(''), isNull);
    expect(assetUrl('listings/1/x.jpg'), endsWith('/storage/listings/1/x.jpg'));
    expect(assetUrl('https://cdn/y.jpg'), 'https://cdn/y.jpg');
  });

  test('User.fromJson maps snake_case correctly', () {
    final u = User.fromJson({
      'id': 1,
      'phone': '+9647700000001',
      'is_registration_completed': true,
      'supported_club_id': 5,
      'roles': ['seller'],
    });
    expect(u.id, 1);
    expect(u.isRegistrationCompleted, isTrue);
    expect(u.supportedClubId, 5);
    expect(u.hasRole('seller'), isTrue);
    expect(u.hasRole('club-admin'), isFalse);
  });

  test('AppConfig reads dotted setting keys', () {
    final c = AppConfig.fromJson({
      'version': {'force_update': false, 'update_available': true},
      'settings': {
        'match.live_poll_seconds': 45,
        'clubs.verification_enabled': true,
      },
    });
    expect(c.version?.hasGate, isTrue);
    expect(c.version?.forceUpdate, isFalse);
    expect(c.livePollSeconds, 45);
    expect(c.clubsVerificationEnabled, isTrue);
    expect(c.fanGroupsVerificationEnabled, isFalse);
  });
}
