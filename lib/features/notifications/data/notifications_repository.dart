import 'package:iqs_flutter/core/api/api_models.dart';
import 'package:iqs_flutter/core/network/api_client.dart';

import 'app_notification.dart';

/// In-app notifications inbox (Phase 8).
class NotificationsRepository {
  NotificationsRepository(this._api);

  final ApiClient _api;

  Future<Paginated<AppNotification>> list({bool unread = false, int page = 1}) {
    final query = <String, dynamic>{'page': page, 'per_page': 20};
    if (unread) query['unread'] = true;
    return _api.getPaged('/notifications',
        query: query, parseItem: AppNotification.fromJson);
  }

  Future<int> unreadCount() => _api.get(
        '/notifications/unread-count',
        parse: (d) =>
            ((d as Map)['count'] as num?)?.toInt() ?? 0,
      );

  /// Owner-checked server-side (403 if not yours).
  Future<void> markRead(int id) =>
      _api.post('/notifications/$id/read', parse: (_) {});

  Future<void> markAllRead() =>
      _api.post('/notifications/read-all', parse: (_) {});
}
