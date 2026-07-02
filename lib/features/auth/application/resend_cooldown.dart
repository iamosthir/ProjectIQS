import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:iqs_flutter/core/core_providers.dart';
import 'package:iqs_flutter/core/storage/app_prefs.dart';

/// Counts down the OTP **resend** cooldown (seconds remaining) for one phone.
///
/// The target time is persisted to [AppPrefs] keyed by phone, so the countdown
/// survives leaving the OTP screen and a full app restart — the remaining time
/// is always recomputed from the stored epoch, never from an in-memory tick.
/// State == 0 means a resend is allowed.
class ResendCooldownNotifier extends StateNotifier<int> {
  ResendCooldownNotifier(this._prefs, this._phone) : super(0) {
    _resumeFromStore();
  }

  final AppPrefs _prefs;
  final String _phone;
  Timer? _timer;

  static int _now() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

  /// Start (or replace) a cooldown of [seconds] from now. Persisted so it
  /// outlives this screen. A non-positive value clears any active cooldown.
  void start(int seconds) {
    if (seconds <= 0) {
      _clear();
      return;
    }
    final until = _now() + seconds;
    _prefs.setOtpResendUntil(_phone, until);
    _runTo(until);
  }

  void _resumeFromStore() {
    final until = _prefs.otpResendUntil(_phone);
    if (until != null && until > _now()) {
      _runTo(until);
    } else if (until != null) {
      _prefs.clearOtpResendUntil(_phone);
    }
  }

  void _runTo(int untilEpoch) {
    _timer?.cancel();
    _tick(untilEpoch);
    if (state > 0) {
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _tick(untilEpoch),
      );
    }
  }

  void _tick(int untilEpoch) {
    final remaining = untilEpoch - _now();
    if (remaining <= 0) {
      _timer?.cancel();
      _prefs.clearOtpResendUntil(_phone);
      if (mounted) state = 0;
    } else if (mounted) {
      state = remaining;
    }
  }

  void _clear() {
    _timer?.cancel();
    _prefs.clearOtpResendUntil(_phone);
    if (mounted) state = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Resend-cooldown for a given phone. Auto-disposes when no screen watches it;
/// the persisted target keeps the countdown correct across re-entry.
final resendCooldownProvider = StateNotifierProvider.autoDispose
    .family<ResendCooldownNotifier, int, String>(
  (ref, phone) => ResendCooldownNotifier(ref.read(appPrefsProvider), phone),
);
