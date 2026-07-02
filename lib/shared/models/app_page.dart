import 'package:flutter/foundation.dart';

import 'package:iqs_flutter/core/util/date_fmt.dart';

/// Static legal/info page from `GET /pages/:slug` (privacy, terms, about).
/// Named [AppPage] to avoid clashing with Flutter's `Page`.
@immutable
class AppPage {
  const AppPage({
    required this.slug,
    required this.title,
    required this.content,
    this.updatedAt,
  });

  final String slug;
  final String title;
  final String content;
  final DateTime? updatedAt;

  factory AppPage.fromJson(Map<String, dynamic> j) => AppPage(
        slug: j['slug']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        content: j['content']?.toString() ?? '',
        updatedAt: DateFmt.tryParse(j['updated_at'] as String?),
      );
}
