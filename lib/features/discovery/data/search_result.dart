import 'package:flutter/foundation.dart';

/// A global-search hit (`GET /search` → `data.results[]`). `type` is one of
/// team | player | club | fan_group | listing.
@immutable
class SearchResult {
  const SearchResult({
    required this.type,
    required this.id,
    required this.title,
    this.subtitle,
    this.image,
  });

  final String type;
  final int id;
  final String title;
  final String? subtitle;
  final String? image;

  factory SearchResult.fromJson(Map<String, dynamic> j) => SearchResult(
        type: j['type']?.toString() ?? '',
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: j['title']?.toString() ?? '',
        subtitle: j['subtitle'] as String?,
        image: j['image'] as String?,
      );

  /// The detail route for this hit, or null when no route exists yet.
  String? get route {
    switch (type) {
      case 'team':
        return '/teams/$id';
      case 'player':
        return '/players/$id';
      case 'club':
        return '/clubs/$id';
      case 'fan_group':
        return '/fan-groups/$id';
      case 'listing':
        return '/listings/$id';
      default:
        return null;
    }
  }
}
