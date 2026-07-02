import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iqs_flutter/core/network/network_providers.dart';
import 'package:iqs_flutter/features/marketplace/data/listing.dart';
import 'package:iqs_flutter/features/marketplace/data/marketplace_category.dart';
import 'package:iqs_flutter/features/marketplace/data/marketplace_repository.dart';
import 'package:iqs_flutter/features/marketplace/data/store.dart';

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>(
  (ref) => MarketplaceRepository(ref.watch(apiClientProvider)),
);

/// Auto-dispose so a transient failure isn't cached for the whole session —
/// re-entering the marketplace refetches. The screen surfaces error+retry.
final categoriesProvider =
    FutureProvider.autoDispose<List<MarketplaceCategory>>(
  (ref) => ref.watch(marketplaceRepositoryProvider).categories(),
);

/// Auto-dispose so re-entry re-fetches (and re-increments views server-side).
final listingDetailProvider = FutureProvider.autoDispose.family<Listing, int>(
  (ref, id) => ref.watch(marketplaceRepositoryProvider).listing(id),
);

/// The seller's own store (`null` when they haven't created one). Invalidate
/// after create/edit. Drives the seller gating (my-store ≠ null).
final myStoreProvider = FutureProvider<Store?>(
  (ref) => ref.watch(marketplaceRepositoryProvider).myStore(),
);
