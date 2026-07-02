import 'package:iqs_flutter/core/network/api_client.dart';

/// FCM device-token registration (Phase 8). Called by the push layer on
/// login/token-refresh (register) and logout (unregister).
class DevicesRepository {
  DevicesRepository(this._api);

  final ApiClient _api;

  /// `platform` ∈ android|ios (DevicePlatform enum).
  Future<void> register({
    required String token,
    required String platform,
    String? deviceId,
    String? deviceName,
    String? appVersion,
  }) {
    final body = <String, dynamic>{'token': token, 'platform': platform};
    if (deviceId != null) body['device_id'] = deviceId;
    if (deviceName != null) body['device_name'] = deviceName;
    if (appVersion != null) body['app_version'] = appVersion;
    return _api.post('/devices/register', data: body, parse: (_) {});
  }

  /// DELETE with a JSON body (`{token}`) — Dio `data:`, not query.
  Future<void> unregister(String token) => _api.delete(
        '/devices/unregister',
        data: {'token': token},
        parse: (_) {},
      );
}
