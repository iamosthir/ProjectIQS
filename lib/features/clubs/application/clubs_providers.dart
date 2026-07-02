import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iqs_flutter/features/clubs/data/club.dart';
import 'package:iqs_flutter/features/clubs/data/club_detail.dart';
import 'package:iqs_flutter/features/discovery/application/discovery_providers.dart';

/// Auto-dispose so re-entry re-fetches the profile.
final clubDetailProvider = FutureProvider.autoDispose.family<ClubDetail, int>(
  (ref, id) => ref.watch(clubsRepositoryProvider).clubDetail(id),
);

/// Auto-dispose so re-opening an article re-fetches (re-increments views).
final clubNewsArticleProvider =
    FutureProvider.autoDispose.family<ClubNews, ({int clubId, int newsId})>(
  (ref, key) =>
      ref.watch(clubsRepositoryProvider).clubNewsArticle(key.clubId, key.newsId),
);

/// The club the user manages. Errors with ApiException(403) when they don't
/// manage one (the dashboard treats 403 as "not a club-admin").
final myClubProvider = FutureProvider<ClubDetail>(
  (ref) => ref.watch(clubsRepositoryProvider).myClub(),
);
