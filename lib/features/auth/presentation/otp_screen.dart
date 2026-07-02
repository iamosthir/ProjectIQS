import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/core/config/env.dart';
import 'package:iqs_flutter/core/network/api_exception.dart';
import 'package:iqs_flutter/features/auth/application/auth_providers.dart';
import 'package:iqs_flutter/features/auth/application/resend_cooldown.dart';
import 'package:iqs_flutter/features/auth/data/auth_dtos.dart';
import 'package:iqs_flutter/shared/l10n/app_localizations.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/shared/widgets/clay_text_field.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_button.dart';
import 'package:iqs_flutter/widgets/clay_icon_button.dart';

/// Arguments passed to `/otp` via go_router `extra`.
class OtpArgs {
  const OtpArgs({required this.phone, required this.challenge});
  final String phone;
  final OtpChallenge challenge;
}

/// OTP verification (`/otp`). On success the auth state changes and the router
/// redirect routes to `/home` or `/register` — no manual navigation here.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.args});

  final OtpArgs args;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otp = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  String? _error;
  late OtpChallenge _challenge;

  String get _phone => widget.args.phone;

  @override
  void initState() {
    super.initState();
    _challenge = widget.args.challenge;
    // Start the resend cooldown for the code that was just sent — unless a
    // cooldown is already running for this phone (restored from prefs after a
    // screen re-entry / app restart), in which case we keep the remaining time.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(resendCooldownProvider(_phone).notifier);
      if (ref.read(resendCooldownProvider(_phone)) <= 0) {
        notifier.start(_challenge.resendAvailableIn);
      }
    });
  }

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    final code = _otp.text.trim();
    if (code.length != 6) {
      setState(() => _error = context.l10n.authOtpSixDigits);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .verifyOtp(phone: widget.args.phone, otp: code);
      // Success → auth state changed → router redirect handles navigation.
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.fieldError('otp') ?? e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_resending) return;
    // Guard against a too-early tap even if the button is somehow enabled.
    if (ref.read(resendCooldownProvider(_phone)) > 0) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    final cooldown = ref.read(resendCooldownProvider(_phone).notifier);
    try {
      final challenge =
          await ref.read(authProvider.notifier).requestOtp(_phone);
      if (!mounted) return;
      setState(() => _challenge = challenge);
      cooldown.start(challenge.resendAvailableIn);
    } on ApiException catch (e) {
      if (!mounted) return;
      // 429 → the server told us exactly how long to wait: drive the countdown
      // from retry_after and keep resend disabled. Do not auto-retry.
      if (e.isThrottled) {
        cooldown.start(e.retryAfter ?? _challenge.resendAvailableIn);
      }
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final debugOtp = _challenge.debugOtp;
    final l10n = AppLocalizations.of(context);
    final secondsLeft = ref.watch(resendCooldownProvider(_phone));
    final canResend = secondsLeft <= 0;
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
                      child:
                          Text(l10n.authOtpTitle, style: AppText.screenTitle),
                    ),
                  ),
                  ClayHeaderButton(
                    icon: Icons.chevron_left,
                    onTap: () => context.pop(),
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
                    l10n.authOtpSentTo,
                    style: AppText.tajawal(
                      size: 18,
                      weight: AppText.extraBold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      _challenge.maskedPhone.isEmpty
                          ? widget.args.phone
                          : _challenge.maskedPhone,
                      style: AppText.tajawal(
                        size: 15,
                        weight: AppText.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ClayTextField(
                    controller: _otp,
                    hint: '••••••',
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    autofocus: true,
                    errorText: _error,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    textStyle: AppText.tajawal(
                      size: 26,
                      weight: AppText.black,
                      color: AppColors.textPrimary,
                      letterSpacing: 10,
                    ),
                    onChanged: (v) {
                      if (_error != null) setState(() => _error = null);
                      if (v.length == 6) _verify();
                    },
                  ),
                  if (debugOtp != null && Env.isDebug) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        _otp.text = debugOtp;
                        _verify();
                      },
                      child: Text(
                        l10n.authDebugOtpFill(debugOtp),
                        textAlign: TextAlign.center,
                        style: AppText.tajawal(
                          size: 12,
                          weight: AppText.bold,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _loading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: LoadingState(),
                        )
                      : Clay3DButton(
                          label: l10n.confirm,
                          gradient: AppColors.login3d,
                          hardShadow: AppColors.login3dHardShadow,
                          softShadow: [
                            BoxShadow(
                              color: const Color(0xFF19773B)
                                  .withValues(alpha: 0.55),
                              blurRadius: 22,
                              offset: const Offset(0, 12),
                              spreadRadius: -6,
                            ),
                          ],
                          height: 62,
                          radius: 20,
                          onTap: _verify,
                        ),
                  const SizedBox(height: 20),
                  Center(
                    child: _resending
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryGreen,
                            ),
                          )
                        : canResend
                            ? GestureDetector(
                                onTap: _resend,
                                child: Text(
                                  l10n.resendCode,
                                  style: AppText.tajawal(
                                    size: 14,
                                    weight: AppText.bold,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              )
                            : Text(
                                l10n.resendIn(secondsLeft),
                                style: AppText.muted,
                              ),
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
