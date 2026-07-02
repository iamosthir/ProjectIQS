import 'package:flutter/foundation.dart';

/// `meta.pagination` from the success envelope. Exactly four keys, per the
/// backend contract — no `links`/`next_url`.
@immutable
class PageMeta {
  const PageMeta({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  bool get hasMore => currentPage < lastPage;

  factory PageMeta.fromJson(Map<String, dynamic> json) => PageMeta(
        currentPage: (json['current_page'] as num?)?.toInt() ?? 1,
        perPage: (json['per_page'] as num?)?.toInt() ?? 20,
        total: (json['total'] as num?)?.toInt() ?? 0,
        lastPage: (json['last_page'] as num?)?.toInt() ?? 1,
      );

  /// Single-page fallback used when an endpoint returns a bare array (no meta).
  factory PageMeta.single(int count) =>
      PageMeta(currentPage: 1, perPage: count, total: count, lastPage: 1);
}

/// A page of [T] plus its pagination metadata. Accumulate across pages with
/// [appended].
@immutable
class Paginated<T> {
  const Paginated({required this.items, required this.meta});

  final List<T> items;
  final PageMeta meta;

  bool get hasMore => meta.hasMore;
  int get currentPage => meta.currentPage;

  /// Returns a new page whose items are this page's items followed by [next]'s,
  /// carrying [next]'s meta (so [hasMore]/[currentPage] reflect the latest fetch).
  Paginated<T> appended(Paginated<T> next) =>
      Paginated(items: [...items, ...next.items], meta: next.meta);

  static Paginated<T> empty<T>() =>
      Paginated(items: const [], meta: PageMeta.single(0));
}
