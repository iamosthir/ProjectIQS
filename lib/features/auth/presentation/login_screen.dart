import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/core/network/api_exception.dart';
import 'package:iqs_flutter/core/util/validators.dart';
import 'package:iqs_flutter/features/auth/application/auth_providers.dart';
import 'package:iqs_flutter/features/auth/application/resend_cooldown.dart';
import 'package:iqs_flutter/features/auth/data/auth_dtos.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/shared/widgets/clay_text_field.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_button.dart';
import 'package:iqs_flutter/widgets/clay_icon_button.dart';
import 'otp_screen.dart';

/// Phone entry (`/login`). Iraq-only; sends a normalized `+9647XXXXXXXXX` to
/// `POST /auth/request-otp` and pushes `/otp` with the challenge.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  static final _valid = RegExp(r'^\+9647\d{9}$');

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final phone = Validators.normalizeIraqiPhone(_phone.text);
    if (!_valid.hasMatch(phone)) {
      setState(() => _error = context.l10n.authInvalidIraqiPhone);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final challenge =
          await ref.read(authProvider.notifier).requestOtp(phone);
      if (!mounted) return;
      ref
          .read(resendCooldownProvider(phone).notifier)
          .start(challenge.resendAvailableIn);
      context.push('/otp', extra: OtpArgs(phone: phone, challenge: challenge));
    } on ApiException catch (e) {
      if (!mounted) return;
      // A too-soon retry (e.g. relaunching after a code was already sent)
      // returns 429 with retry_after. A code is still pending, so route to the
      // OTP screen with the cooldown running rather than blocking here.
      if (e.isThrottled) {
        final retry = e.retryAfter ?? 60;
        ref.read(resendCooldownProvider(phone).notifier).start(retry);
        context.push(
          '/otp',
          extra: OtpArgs(
            phone: phone,
            challenge: OtpChallenge(
              maskedPhone: '',
              expiresIn: 300,
              resendAvailableIn: retry,
            ),
          ),
        );
        return;
      }
      setState(() => _error = e.fieldError('phone') ?? e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(
              bottomRadius: 36,
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
              child: Row(
                children: [
                  const SizedBox(width: 50),
                  Expanded(
                    child: Center(
                      child: Text(context.l10n.authLoginButton,
                          style: AppText.screenTitle),
                    ),
                  ),
                  ClayHeaderButton(
                    icon: Icons.chevron_left,
                    onTap: () => context.go('/welcome'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.authEnterPhoneTitle,
                    style: AppText.tajawal(
                      size: 20,
                      weight: AppText.extraBold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.authEnterPhoneSubtitle,
                    style: AppText.muted,
                  ),
                  const SizedBox(height: 24),
                  ClayTextField(
                    controller: _phone,
                    hint: '7XX XXX XXXX',
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    // No length cap: a user pasting the full `+9647…` must not be
                    // truncated before _normalize() strips the country code. The
                    // counter is hidden (counterText:''), so this is invisible.
                    errorText: _error,
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    onSubmitted: (_) => _submit(),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                    ],
                    prefix: Text(
                      '+964',
                      style: AppText.tajawal(
                        size: 16,
                        weight: AppText.extraBold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _loading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: LoadingState(),
                        )
                      : Clay3DButton(
                          label: context.l10n.authContinue,
                          gradient: AppColors.login3d,
                          hardShadow: AppColors.login3dHardShadow,
                          softShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFF19773B).withValues(alpha: 0.55),
                              blurRadius: 22,
                              offset: const Offset(0, 12),
                              spreadRadius: -6,
                            ),
                          ],
                          height: 62,
                          radius: 20,
                          onTap: _submit,
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
