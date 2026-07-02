import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iqs_flutter/core/core_providers.dart';
import 'package:iqs_flutter/core/network/api_exception.dart';
import 'package:iqs_flutter/core/network/network_providers.dart';
import 'package:iqs_flutter/features/auth/data/auth_dtos.dart';
import 'package:iqs_flutter/features/auth/data/auth_repository.dart';
import 'package:iqs_flutter/features/notifications/application/push_service.dart';
import 'package:iqs_flutter/shared/models/user.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

enum AuthStatus { unauthenticated, needsRegistration, authenticated }

@immutable
class AuthState {
  const AuthState._(this.status, this.user);

  final AuthStatus status;
  final User? user;

  factory AuthState.unauthenticated() =>
      const AuthState._(AuthStatus.unauthenticated, null);
  factory AuthState.needsRegistration(User user) =>
      AuthState._(AuthStatus.needsRegistration, user);
  factory AuthState.authenticated(User user) =>
      AuthState._(AuthStatus.authenticated, user);

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isNeedsRegistration => status == AuthStatus.needsRegistration;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;

  static AuthState forUser(User user) => user.isRegistrationCompleted
      ? AuthState.authenticated(user)
      : AuthState.needsRegistration(user);
}

/// Session state machine. `build()` restores from the stored token; the OTP /
/// register / logout methods drive transitions. Listens to the core 401 signal
/// so an expired token anywhere drops the session.
class AuthNotifier extends AsyncNotifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<AuthState> build() async {
    ref.listen<int>(unauthorizedSignalProvider, (prev, next) {
      if (prev != next) {
        // Token already cleared by ApiClient — just reflect it.
        state = AsyncData(AuthState.unauthenticated());
      }
    });

    final tokenStore = ref.read(secureTokenStoreProvider);
    final token = await tokenStore.read();
    if (token == null) return AuthState.unauthenticated();

    try {
      final user = await _repo.me();
      return AuthState.forUser(user);
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await tokenStore.clear();
        return AuthState.unauthenticated();
      }
      rethrow; // network/server error → AsyncError → splash offers retry
    }
  }

  Future<OtpChallenge> requestOtp(String phone) => _repo.requestOtp(phone);

  Future<AuthResult> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final result = await _repo.verifyOtp(phone: phone, otp: otp);
    await ref.read(secureTokenStoreProvider).write(result.token);
    final next = result.needsRegistration
        ? AuthState.needsRegistration(result.user)
        : AuthState.forUser(result.user);
    state = AsyncData(next);
    return result;
  }

  /// Completes profile (`POST /auth/register`). [body] uses raw API keys
  /// (`name`, `email`, `governorate`, `gender`, `date_of_birth`,
  /// `supported_club_id`, `supported_team_id`).
  Future<User> completeRegistration(Map<String, dynamic> body) async {
    final user = await _repo.register(body);
    state = AsyncData(AuthState.forUser(user));
    return user;
  }

  Future<void> refreshUser() async {
    final user = await _repo.me();
    state = AsyncData(AuthState.forUser(user));
  }

  /// Partial profile update (`PUT /auth/profile`) → reflect the fresh user.
  Future<User> updateProfile(Map<String, dynamic> body) async {
    final user = await _repo.updateProfile(body);
    state = AsyncData(AuthState.forUser(user));
    return user;
  }

  Future<void> logout() async {
    // Deregister this device FIRST — the Bearer is still valid here; after the
    // token is revoked/cleared the call would 401. Best-effort (no-op if push
    // is unavailable).
    await ref.read(pushServiceProvider).unregisterToken();
    try {
      await _repo.logout();
    } catch (_) {
      // Best-effort token revoke; clear locally regardless.
    }
    await ref.read(secureTokenStoreProvider).clear();
    state = AsyncData(AuthState.unauthenticated());
  }

  Future<void> deleteAccount() async {
    await _repo.deleteAccount();
    await ref.read(secureTokenStoreProvider).clear();
    state = AsyncData(AuthState.unauthenticated());
  }
}

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Convenience: the current user (null while loading / unauthenticated).
final currentUserProvider = Provider<User?>(
  (ref) => ref.watch(authProvider).valueOrNull?.user,
);
