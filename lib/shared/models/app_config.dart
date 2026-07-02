import 'package:flutter/foundation.dart';

/// Version-gate block from `GET /app/config`.
@immutable
class AppVersion {
  const AppVersion({
    this.latest,
    this.minSupported,
    this.updateAvailable = false,
    this.forceUpdate = false,
    this.storeUrl,
    this.changelog,
  });

  final String? latest;
  final String? minSupported;
  final bool updateAvailable;
  final bool forceUpdate;
  final String? storeUrl;
  final String? changelog;

  /// True when the splash should route to `/update` (force = blocking).
  bool get hasGate => updateAvailable || forceUpdate;

  factory AppVersion.fromJson(Map<String, dynamic> j) => AppVersion(
        latest: j['latest'] as String?,
        minSupported: j['min_supported'] as String?,
        updateAvailable: j['update_available'] == true,
        forceUpdate: j['force_update'] == true,
        storeUrl: j['store_url'] as String?,
        changelog: j['changelog'] as String?,
      );
}

/// `GET /app/config` payload: optional version gate + a flat settings map of
/// dotted keys (e.g. `match.live_poll_seconds`, `clubs.verification_enabled`).
@immutable
class AppConfig {
  const AppConfig({this.version, this.settings = const {}});

  final AppVersion? version;
  final Map<String, dynamic> settings;

  factory AppConfig.fromJson(Map<String, dynamic> j) => AppConfig(
        version: j['version'] is Map
            ? AppVersion.fromJson((j['version'] as Map).cast<String, dynamic>())
            : null,
        settings: (j['settings'] as Map?)?.cast<String, dynamic>() ?? const {},
      );

  // ---- typed setting accessors ----
  String? get appName => settings['general.app_name'] as String?;
  String? get supportEmail => settings['general.support_email'] as String?;
  String? get supportPhone => settings['general.support_phone'] as String?;
  int get livePollSeconds =>
      (settings['match.live_poll_seconds'] as num?)?.toInt() ?? 60;
  bool get clubsVerificationEnabled =>
      settings['clubs.verification_enabled'] == true;
  bool get fanGroupsVerificationEnabled =>
      settings['fan_groups.verification_enabled'] == true;
}
