import 'package:flutter/foundation.dart';

import 'package:iqs_flutter/core/util/date_fmt.dart';

/// A club (`GET /clubs`). `team_id` links to a Team (null when unlinked → the
/// Matches/Players/Stats tabs are hidden on the club profile, Phase 5).
@immutable
class Club {
  const Club({
    required this.id,
    required this.name,
    this.slug,
    this.logo,
    this.cover,
    this.governorate,
    this.city,
    this.foundedYear,
    this.isVerified = false,
    this.teamId,
  });

  final int id;
  final String name;
  final String? slug;
  final String? logo;
  final String? cover;
  final String? governorate;
  final String? city;
  final int? foundedYear;
  final bool isVerified;
  final int? teamId;

  factory Club.fromJson(Map<String, dynamic> j) => Club(
        id: (j['id'] as num).toInt(),
        name: j['name']?.toString() ?? '',
        slug: j['slug'] as String?,
        logo: j['logo'] as String?,
        cover: j['cover'] as String?,
        governorate: j['governorate'] as String?,
        city: j['city'] as String?,
        foundedYear: (j['founded_year'] as num?)?.toInt(),
        isVerified: j['is_verified'] == true,
        teamId: (j['team_id'] as num?)?.toInt(),
      );
}

/// A club news article row (`GET /clubs/:id/news`). [clubId] is injected by the
/// repository (the row itself doesn't carry it).
@immutable
class ClubNews {
  const ClubNews({
    required this.id,
    required this.title,
    this.slug,
    this.excerpt,
    this.cover,
    this.authorName,
    this.viewsCount = 0,
    this.publishedAt,
    this.content,
    this.clubId,
    this.clubName,
  });

  final int id;
  final String title;
  final String? slug;
  final String? excerpt;
  final String? cover;
  final String? authorName;
  final int viewsCount;
  final DateTime? publishedAt;

  /// Full body — present only on the article endpoint.
  final String? content;
  final int? clubId;
  final String? clubName;

  factory ClubNews.fromJson(Map<String, dynamic> j,
          {int? clubId, String? clubName}) =>
      ClubNews(
        id: (j['id'] as num).toInt(),
        title: j['title']?.toString() ?? '',
        slug: j['slug'] as String?,
        excerpt: j['excerpt'] as String?,
        cover: j['cover'] as String?,
        authorName: j['author_name'] as String?,
        viewsCount: (j['views_count'] as num?)?.toInt() ?? 0,
        publishedAt: DateFmt.tryParse(j['published_at'] as String?),
        content: j['content'] as String?,
        clubId: clubId,
        clubName: clubName,
      );
}
