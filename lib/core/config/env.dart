import 'package:flutter/foundation.dart';

/// Build flavor. The default is `dev` (the local LAN server). Build for the
/// live API with `--dart-define=FLAVOR=prod`. Each flavor has a default host;
/// override either host explicitly with
/// `--dart-define=API_BASE=... --dart-define=STORAGE_BASE=...`.
enum Flavor { dev, staging, prod }

/// Single source of truth for environment configuration.
///
/// Default host is the local Laravel dev server (`http://192.168.0.188:8000`);
/// for the Android emulator override with
/// `--dart-define=API_BASE=http://10.0.2.2:8000`. Build for the live API
/// (`https://apifootball.teknoiq.com`) with `--dart-define=FLAVOR=prod`. Images
/// are served at `$storageBase/storage/<path>`.
class Env {
  Env._();

  // Default flavor: 'dev' = local LAN server, 'prod' = live (apifootball.teknoiq.com).
  // Flip this one value to switch the default for every build.
  static const String _flavorName =
      String.fromEnvironment('FLAVOR', defaultValue: 'prod');

  /// The active build flavor.
  static Flavor get flavor => switch (_flavorName) {
        'dev' => Flavor.dev,
        'staging' => Flavor.staging,
        _ => Flavor.prod,
      };

  static bool get isProd => flavor == Flavor.prod;

  /// Client app version, sent to `GET /app/config` for the version gate.
  /// Keep in sync with `pubspec.yaml`'s `version:`.
  static const String appVersion = '1.0.0';

  static const String _apiBaseOverride =
      String.fromEnvironment('API_BASE', defaultValue: '');
  static const String _storageBaseOverride =
      String.fromEnvironment('STORAGE_BASE', defaultValue: '');

  /// Default host per flavor. `dev` is the local LAN server; staging/prod point
  /// at the live domain (set a distinct staging host here if one exists).
  static String get _defaultHost => switch (flavor) {
        Flavor.dev => 'http://192.168.0.188:8000',
        Flavor.staging => 'https://apifootball.teknoiq.com',
        Flavor.prod => 'https://apifootball.teknoiq.com',
      };

  /// Base host for the API. `/api/v1` is appended by [apiV1].
  static String get apiBase =>
      _apiBaseOverride.isNotEmpty ? _apiBaseOverride : _defaultHost;

  /// Base host for storage assets. Images are served at
  /// `$storageBase/storage/<path>`. Defaults to the API host.
  static String get storageBase =>
      _storageBaseOverride.isNotEmpty ? _storageBaseOverride : apiBase;

  /// Full API root, e.g. `https://apifootball.teknoiq.com/api/v1`.
  static String get apiV1 => '$apiBase/api/v1';

  static bool get isDebug => kDebugMode;
}
