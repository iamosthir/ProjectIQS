import 'package:iqs_flutter/core/network/api_client.dart';
import 'package:iqs_flutter/shared/models/user.dart';

import 'auth_dtos.dart';

/// All `/auth/*` calls. Throws [ApiException] on failure; the notifier wraps
/// these in `AsyncValue`.
class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<OtpChallenge> requestOtp(String phone) => _api.post(
        '/auth/request-otp',
        data: {'phone': phone},
        parse: (d) => OtpChallenge.fromJson((d as Map).cast<String, dynamic>()),
      );

  Future<AuthResult> verifyOtp({
    required String phone,
    required String otp,
  }) =>
      _api.post(
        '/auth/verify-otp',
        data: {'phone': phone, 'otp': otp},
        parse: (d) => AuthResult.fromJson((d as Map).cast<String, dynamic>()),
      );

  /// Completes the profile after first login. Returns the updated user
  /// (`is_registration_completed` flips to true). Send governorate `code`.
  Future<User> register(Map<String, dynamic> body) => _api.post(
        '/auth/register',
        data: body,
        parse: (d) => User.fromJson((d as Map).cast<String, dynamic>()),
      );

  Future<User> me() => _api.get(
        '/auth/me',
        parse: (d) => User.fromJson((d as Map).cast<String, dynamic>()),
      );

  /// Partial profile update (`PUT /auth/profile`). Send only changed keys
  /// (`name`, `email`, `avatar`, `governorate` code, `gender`, `date_of_birth`,
  /// `locale`, `supported_club_id`, `supported_team_id`). Returns the fresh user.
  Future<User> updateProfile(Map<String, dynamic> body) => _api.put(
        '/auth/profile',
        data: body,
        parse: (d) => User.fromJson((d as Map).cast<String, dynamic>()),
      );

  Future<void> logout() => _api.post('/auth/logout', parse: (_) {});

  Future<void> deleteAccount() => _api.delete('/auth/account', parse: (_) {});
}
