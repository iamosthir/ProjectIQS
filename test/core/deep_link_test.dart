import 'package:flutter_test/flutter_test.dart';

import 'package:iqs_flutter/core/routing/deep_link.dart';

void main() {
  group('DeepLink', () {
    test('fromJson reads action_type/action_value with a none default', () {
      final d = DeepLink.fromJson({'action_type': 'club', 'action_value': '9'});
      expect(d.actionType, 'club');
      expect(d.actionValue, '9');
      expect(d.isActionable, isTrue);

      final none = DeepLink.fromJson({});
      expect(none.actionType, 'none');
      expect(none.isActionable, isFalse);
    });

    test('isActionable is false for none / empty', () {
      expect(const DeepLink(actionType: 'none', actionValue: '1').isActionable,
          isFalse);
      expect(const DeepLink(actionType: '', actionValue: '1').isActionable,
          isFalse);
      expect(const DeepLink(actionType: 'fixture', actionValue: '1').isActionable,
          isTrue);
    });
  });
}
