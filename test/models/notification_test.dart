import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iqs_flutter/features/notifications/data/app_notification.dart';

void main() {
  group('AppNotification.fromJson', () {
    test('maps localized fields + deep-link + read state', () {
      final n = AppNotification.fromJson({
        'id': 3,
        'title': 'هدف!',
        'body': 'سجل فريقك هدفاً',
        'type': 'goal',
        'action_type': 'fixture',
        'action_value': '42',
        'image': 'notifications/3.png',
        'data': {'extra': 1},
        'is_read': false,
        'created_at': '2026-07-05T10:00:00+00:00',
      });
      expect(n.id, 3);
      expect(n.title, 'هدف!');
      expect(n.type, 'goal');
      expect(n.isRead, isFalse);
      expect(n.data?['extra'], 1);
      // Deep link feeds the shared router (never routes by `type`).
      expect(n.deepLink.actionType, 'fixture');
      expect(n.deepLink.actionValue, '42');
      expect(n.deepLink.isActionable, isTrue);
    });

    test('a none/empty action is not actionable', () {
      final n = AppNotification.fromJson({
        'id': 4,
        'title': 'إشعار',
        'body': '',
        'type': 'system',
        'action_type': 'none',
      });
      expect(n.deepLink.isActionable, isFalse);
      expect(n.actionValue, isNull);
    });

    test('copyWith flips isRead only', () {
      final n = AppNotification.fromJson({'id': 1, 'title': 't', 'body': 'b'});
      final read = n.copyWith(isRead: true);
      expect(read.isRead, isTrue);
      expect(read.title, 't');
      expect(n.isRead, isFalse); // immutable original unchanged
    });

    test('notificationIcon maps types to icons (iconography only)', () {
      expect(notificationIcon('match'), Icons.sports_soccer);
      expect(notificationIcon('payment'), Icons.payments_outlined);
      expect(notificationIcon('unknown-type'), Icons.notifications_none_rounded);
    });
  });
}
