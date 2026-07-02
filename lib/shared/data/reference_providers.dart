import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iqs_flutter/core/config/env.dart';
import 'package:iqs_flutter/core/network/network_providers.dart';
import 'package:iqs_flutter/shared/data/reference_repository.dart';
import 'package:iqs_flutter/shared/models/app_config.dart';
import 'package:iqs_flutter/shared/models/app_page.dart';
import 'package:iqs_flutter/shared/models/governorate.dart';

final referenceRepositoryProvider = Provider<ReferenceRepository>(
  (ref) => ReferenceRepository(ref.watch(apiClientProvider)),
);

/// Version gate + settings. Always sends `platform` & `version` so the flags
/// are meaningful.
final appConfigProvider = FutureProvider<AppConfig>((ref) {
  final platform =
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  return ref
      .watch(referenceRepositoryProvider)
      .appConfig(platform: platform, version: Env.appVersion);
});

/// Governorates list (reused by register, listings, filters). Cached for the
/// session by Riverpod.
final governoratesProvider = FutureProvider<List<Governorate>>(
  (ref) => ref.watch(referenceRepositoryProvider).governorates(),
);

/// A static page by slug (privacy/terms/about).
final pageProvider = FutureProvider.family<AppPage, String>(
  (ref, slug) => ref.watch(referenceRepositoryProvider).page(slug),
);
