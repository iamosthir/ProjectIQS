import 'package:flutter/foundation.dart';

/// A season of a league. `year` is the season YEAR (integer, e.g. 2025) used as
/// the `?season=` query value — NOT the season id.
@immutable
class Season {
  const Season({required this.id, this.year, this.label, this.isCurrent = false});
  final int id;
  final int? year;
  final String? label;
  final bool isCurrent;

  /// Display label — the API `label` when set, else the plain year.
  String get displayLabel => label ?? (year?.toString() ?? '');

  factory Season.fromJson(Map<String, dynamic> j) => Season(
        id: (j['id'] as num).toInt(),
        year: (j['year'] as num?)?.toInt(),
        label: j['label'] as String?,
        isCurrent: j['is_current'] == true,
      );
}

@immutable
class League {
  const League({
    required this.id,
    required this.name,
    this.type,
    this.logo,
    this.isIraqi = false,
    this.category,
    this.tier,
    this.requiresAuth = false,
    this.isFeatured = false,
    this.currentSeason,
    this.seasons = const [],
  });

  final int id;
  final String name;
  final String? type;
  final String? logo;
  final bool isIraqi;
  final String? category;
  final int? tier;
  final bool requiresAuth;
  final bool isFeatured;
  final Season? currentSeason;

  /// All seasons, newest first (populated by the league-detail payload only;
  /// list rows leave it empty).
  final List<Season> seasons;

  factory League.fromJson(Map<String, dynamic> j) => League(
        id: (j['id'] as num).toInt(),
        name: j['name']?.toString() ?? '',
        type: j['type'] as String?,
        logo: j['logo'] as String?,
        isIraqi: j['is_iraqi'] == true,
        category: j['category'] as String?,
        tier: (j['tier'] as num?)?.toInt(),
        requiresAuth: j['requires_auth'] == true,
        isFeatured: j['is_featured'] == true,
        currentSeason: j['current_season'] is Map
            ? Season.fromJson((j['current_season'] as Map).cast<String, dynamic>())
            : null,
        seasons: j['seasons'] is List
            ? (j['seasons'] as List)
                .whereType<Map>()
                .map((e) => Season.fromJson(e.cast<String, dynamic>()))
                .toList()
            : const [],
      );
}
