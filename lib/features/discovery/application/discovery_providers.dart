import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iqs_flutter/core/network/network_providers.dart';
import 'package:iqs_flutter/features/clubs/data/club.dart';
import 'package:iqs_flutter/features/clubs/data/clubs_repository.dart';
import 'package:iqs_flutter/features/discovery/data/app_banner.dart';
import 'package:iqs_flutter/features/discovery/data/discovery_repository.dart';
import 'package:iqs_flutter/features/discovery/data/search_result.dart';

final discoveryRepositoryProvider = Provider<DiscoveryRepository>(
  (ref) => DiscoveryRepository(ref.watch(apiClientProvider)),
);

final clubsRepositoryProvider = Provider<ClubsRepository>(
  (ref) => ClubsRepository(ref.watch(apiClientProvider)),
);

final bannersProvider = FutureProvider<List<AppBanner>>(
  (ref) => ref.watch(discoveryRepositoryProvider).banners(),
);

/// Banners for a placement, ordered by position.
List<AppBanner> bannersForPlacement(List<AppBanner> all, String placement) {
  final list = all.where((b) => b.placement == placement).toList()
    ..sort((a, b) => a.position.compareTo(b.position));
  return list;
}

/// Debounced global search (the screen debounces; this caches per query+type).
/// Returns empty for queries shorter than 2 chars.
final searchProvider = FutureProvider.autoDispose
    .family<List<SearchResult>, ({String q, String? type})>((ref, args) {
  final q = args.q.trim();
  if (q.length < 2) return Future.value(const []);
  return ref.watch(discoveryRepositoryProvider).search(q, type: args.type);
});

/// Home "أحدث الأخبار" strip. No global news endpoint exists, so aggregate the
/// latest news from the first few clubs (bounded) and merge by publish date.
final latestNewsProvider = FutureProvider<List<ClubNews>>((ref) async {
  final repo = ref.watch(clubsRepositoryProvider);
  final clubsPage = await repo.clubs();
  final clubs = clubsPage.items.take(3).toList();
  final results = await Future.wait(
    clubs.map((c) async {
      try {
        final page = await repo.clubNews(c.id, clubName: c.name);
        return page.items;
      } catch (_) {
        return <ClubNews>[];
      }
    }),
  );
  final all = results.expand((x) => x).toList();
  all.sort((a, b) {
    final ad = a.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bd = b.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bd.compareTo(ad);
  });
  return all.take(5).toList();
});
