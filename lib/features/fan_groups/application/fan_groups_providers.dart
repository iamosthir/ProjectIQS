import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iqs_flutter/core/network/network_providers.dart';
import 'package:iqs_flutter/features/fan_groups/data/fan_group.dart';
import 'package:iqs_flutter/features/fan_groups/data/fan_groups_repository.dart';

final fanGroupsRepositoryProvider = Provider<FanGroupsRepository>(
  (ref) => FanGroupsRepository(ref.watch(apiClientProvider)),
);

final fanGroupDetailProvider =
    FutureProvider.autoDispose.family<FanGroupDetail, int>(
  (ref, id) => ref.watch(fanGroupsRepositoryProvider).fanGroupDetail(id),
);

final fanGroupChantsProvider =
    FutureProvider.autoDispose.family<List<FanGroupChant>, int>(
  (ref, id) => ref.watch(fanGroupsRepositoryProvider).fanGroupChants(id),
);

/// The fan group the user manages. Errors with ApiException(403) when they
/// don't manage one (the dashboard treats 403 as "not a group-admin").
final myFanGroupProvider = FutureProvider<FanGroupDetail>(
  (ref) => ref.watch(fanGroupsRepositoryProvider).myFanGroup(),
);

/// All media of the managed group for a given `type` (image|video), across
/// every page — the archive is bounded (≤100 photos / ≤30 videos), so a few
/// requests cover it. Drives the media manager (list + delete).
final myFanGroupMediaProvider =
    FutureProvider.autoDispose.family<List<FanGroupMedia>, String>(
  (ref, type) async {
    final repo = ref.watch(fanGroupsRepositoryProvider);
    final group = await ref.watch(myFanGroupProvider.future);
    final all = <FanGroupMedia>[];
    var page = 1;
    while (true) {
      final p = await repo.fanGroupMedia(group.id, type: type, page: page);
      all.addAll(p.items);
      if (!p.hasMore) break;
      page++;
    }
    return all;
  },
);

/// Chants of the managed group (bare array). Drives the chants manager.
final myFanGroupChantsProvider =
    FutureProvider.autoDispose<List<FanGroupChant>>(
  (ref) async {
    final repo = ref.watch(fanGroupsRepositoryProvider);
    final group = await ref.watch(myFanGroupProvider.future);
    return repo.fanGroupChants(group.id);
  },
);
