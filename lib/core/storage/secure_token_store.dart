import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the Sanctum bearer token in the platform keystore/keychain and
/// keeps a synchronous in-memory cache so interceptors can attach the header
/// without an async read on every request.
///
/// Call [read] once during bootstrap to warm the cache before the first
/// authenticated request.
class SecureTokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'iqs_auth_token';
  final FlutterSecureStorage _storage;

  String? _cached;
  bool _loaded = false;

  /// Synchronous access to the last known token (null until [read] is called).
  String? get cachedToken => _cached;
  bool get hasToken => _cached != null;

  Future<String?> read() async {
    if (_loaded) return _cached;
    _cached = await _storage.read(key: _key);
    _loaded = true;
    return _cached;
  }

  Future<void> write(String token) async {
    _cached = token;
    _loaded = true;
    await _storage.write(key: _key, value: token);
  }

  Future<void> clear() async {
    _cached = null;
    _loaded = true;
    await _storage.delete(key: _key);
  }
}
