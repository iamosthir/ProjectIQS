import 'package:flutter/foundation.dart';

import 'package:iqs_flutter/core/routing/deep_link.dart';

/// A promotional banner (`GET /banners`). `image` is a relative storage path.
/// Grouped client-side by [placement] (`home_top` / `home_middle` /
/// `marketplace_top`) and ordered by [position]; tapping fires its [deepLink].
@immutable
class AppBanner {
  const AppBanner({
    required this.id,
    required this.title,
    this.image,
    this.actionType = 'none',
    this.actionValue,
    this.placement = '',
    this.position = 0,
  });

  final int id;
  final String title;
  final String? image;
  final String actionType;
  final String? actionValue;
  final String placement;
  final int position;

  DeepLink get deepLink =>
      DeepLink(actionType: actionType, actionValue: actionValue);

  factory AppBanner.fromJson(Map<String, dynamic> j) => AppBanner(
        id: (j['id'] as num).toInt(),
        title: j['title']?.toString() ?? '',
        image: j['image'] as String?,
        actionType: (j['action_type'] ?? 'none').toString(),
        actionValue: j['action_value']?.toString(),
        placement: j['placement']?.toString() ?? '',
        position: (j['position'] as num?)?.toInt() ?? 0,
      );
}
