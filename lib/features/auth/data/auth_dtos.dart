import 'package:flutter/foundation.dart';

import 'package:iqs_flutter/core/util/date_fmt.dart';
import 'package:iqs_flutter/shared/models/user.dart';

/// Result of `POST /auth/request-otp`.
@immutable
class OtpChallenge {
  const OtpChallenge({
    required this.maskedPhone,
    required this.expiresIn,
    this.resendAvailableIn = 60,
    this.expiresAt,
    this.debugOtp,
  });

  /// Masked phone the code was sent to, e.g. `+964*******001`.
  final String maskedPhone;

  /// Seconds until the code itself expires. Default 300.
  final int expiresIn;

  /// Seconds before another code can be requested — drives the resend
  /// countdown. A too-early resend returns 429 with a `retry_after` that
  /// supersedes this. Falls back to 60 when the server omits it.
  final int resendAvailableIn;
  final DateTime? expiresAt;

  /// Present only when `OTP_EXPOSE_CODE=true` (dev). Never shown in prod builds.
  final String? debugOtp;

  factory OtpChallenge.fromJson(Map<String, dynamic> j) => OtpChallenge(
        maskedPhone: j['phone']?.toString() ?? '',
        expiresIn: (j['expires_in'] as num?)?.toInt() ?? 300,
        resendAvailableIn: (j['resend_available_in'] as num?)?.toInt() ?? 60,
        expiresAt: DateFmt.tryParse(j['expires_at'] as String?),
        debugOtp: j['debug_otp']?.toString(),
      );
}

/// Result of `POST /auth/verify-otp`. Note `is_new`/`needs_registration` are
/// **top-level** flags in `data`, distinct from `user.is_registration_completed`.
@immutable
class AuthResult {
  const AuthResult({
    required this.token,
    required this.user,
    required this.isNew,
    required this.needsRegistration,
  });

  final String token;
  final User user;
  final bool isNew;
  final bool needsRegistration;

  factory AuthResult.fromJson(Map<String, dynamic> j) => AuthResult(
        token: j['token']?.toString() ?? '',
        user: User.fromJson((j['user'] as Map).cast<String, dynamic>()),
        isNew: j['is_new'] == true,
        needsRegistration: j['needs_registration'] == true,
      );
}
