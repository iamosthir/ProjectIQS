import 'package:flutter/material.dart';

import 'package:iqs_flutter/core/routing/deep_link.dart';
import 'package:iqs_flutter/core/util/date_fmt.dart';

/// An in-app notification (`GET /notifications`). `title`/`body` are
/// server-localized; `type` drives iconography only; `action_type`/`action_value`
/// feed the shared deep-link router (never route by `type`).
@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.actionType,
    this.actionValue,
    this.image,
    this.data,
    this.isRead = false,
    this.createdAt,
  });

  final int id;
  final String title;
  final String body;

  /// general|match|goal|listing|club|fan_group|payment|system — iconography only.
  final String type;
  final String actionType; // none|url|fixture|listing|club|fan_group
  final String? actionValue;
  final String? image;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? createdAt;

  DeepLink get deepLink =>
      DeepLink(actionType: actionType, actionValue: actionValue);

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        body: body,
        type: type,
        actionType: actionType,
        actionValue: actionValue,
        image: image,
        data: data,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: j['title']?.toString() ?? '',
        body: j['body']?.toString() ?? '',
        type: j['type']?.toString() ?? 'general',
        actionType: (j['action_type'] ?? 'none').toString(),
        actionValue: j['action_value']?.toString(),
        image: j['image'] as String?,
        data: (j['data'] is Map)
            ? (j['data'] as Map).cast<String, dynamic>()
            : null,
        isRead: j['is_read'] == true,
        createdAt: DateFmt.tryParse(j['created_at'] as String?),
      );
}

/// Leading icon for a notification `type` (iconography only).
IconData notificationIcon(String type) {
  switch (type) {
    case 'match':
      return Icons.sports_soccer;
    case 'goal':
      return Icons.sports_score;
    case 'listing':
      return Icons.storefront_outlined;
    case 'club':
      return Icons.shield_outlined;
    case 'fan_group':
      return Icons.campaign_outlined;
    case 'payment':
      return Icons.payments_outlined;
    case 'system':
      return Icons.settings_outlined;
    case 'general':
    default:
      return Icons.notifications_none_rounded;
  }
}
