import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iqs_flutter/core/network/network_providers.dart';
import 'package:iqs_flutter/features/notifications/data/devices_repository.dart';
import 'package:iqs_flutter/features/notifications/data/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.watch(apiClientProvider)),
);

final devicesRepositoryProvider = Provider<DevicesRepository>(
  (ref) => DevicesRepository(ref.watch(apiClientProvider)),
);

/// Unread badge count. Plain FutureProvider so it can be invalidated on inbox
/// open, after mark-read/all, and on an FCM data message. Failures resolve to 0
/// (a badge must never block the UI).
final unreadCountProvider = FutureProvider<int>((ref) async {
  try {
    return await ref.watch(notificationsRepositoryProvider).unreadCount();
  } catch (_) {
    return 0;
  }
});
