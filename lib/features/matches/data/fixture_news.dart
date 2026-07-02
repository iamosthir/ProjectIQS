import 'package:flutter/foundation.dart';

import 'package:iqs_flutter/core/util/date_fmt.dart';

/// A match news item (`GET /fixtures/:id/news`). `content` is the full body
/// (in-app article); `url` — when present — points at an external source.
@immutable
class FixtureNews {
  const FixtureNews({
    required this.id,
    required this.title,
    this.excerpt,
    this.content,
    this.cover,
    this.source,
    this.url,
    this.publishedAt,
  });

  final int id;
  final String title;
  final String? excerpt;
  final String? content;
  final String? cover;
  final String? source;
  final String? url;
  final DateTime? publishedAt;

  bool get hasExternalUrl => url != null && url!.isNotEmpty;

  factory FixtureNews.fromJson(Map<String, dynamic> j) => FixtureNews(
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: j['title']?.toString() ?? '',
        excerpt: j['excerpt'] as String?,
        content: j['content'] as String?,
        cover: j['cover'] as String?,
        source: j['source'] as String?,
        url: j['url'] as String?,
        publishedAt: DateFmt.tryParse(j['published_at'] as String?),
      );
}
