import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:iqs_flutter/core/network/api_exception.dart';
import 'package:iqs_flutter/features/payments/application/payments_providers.dart';
import 'package:iqs_flutter/features/payments/data/payment.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_button.dart';
import 'package:iqs_flutter/widgets/clay_card.dart';
import 'package:iqs_flutter/widgets/clay_icon_button.dart';
import 'payment_widgets.dart';

Future<void> _launch(String? raw) async {
  if (raw == null || raw.isEmpty) return;
  final uri = Uri.tryParse(raw);
  if (uri != null && uri.hasScheme) {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {/* ignore */}
  }
}

/// Checkout + polling (`/pay/status/:number`). The initiated [Payment] arrives
/// via `extra` (carrying the transient `redirectUrl`/`qr`); polls `status` every
/// 4s until a final state, with a countdown to `expiresAt`. The app never sees
/// the gateway callback — outcome is learned by polling only.
class PaymentStatusScreen extends ConsumerStatefulWidget {
  const PaymentStatusScreen({
    super.key,
    required this.paymentNumber,
    this.initial,
  });

  final String paymentNumber;
  final Payment? initial;

  @override
  ConsumerState<PaymentStatusScreen> createState() =>
      _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends ConsumerState<PaymentStatusScreen> {
  Payment? _payment;
  // Transient hand-off data — only ever on the initiate response, so capture it
  // once and never overwrite from a poll (status reads return null for these).
  String? _redirectUrl;
  String? _qr;

  Timer? _poll;
  Timer? _ticker;
  bool _expired = false;
  bool _notFound = false;
  bool _fetching = false;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _payment = widget.initial;
    _redirectUrl = widget.initial?.redirectUrl;
    _qr = widget.initial?.qr;
    _recomputeRemaining();
    if (_payment == null) _fetch();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _fetch());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  /// Stop BOTH timers — used at every terminal point (final / expiry / 404) so
  /// the 1s ticker can't keep rebuilding a settled screen.
  void _stopTimers() {
    _poll?.cancel();
    _poll = null;
    _ticker?.cancel();
    _ticker = null;
  }

  void _recomputeRemaining() {
    final exp = _payment?.expiresAt;
    _remaining =
        exp == null ? Duration.zero : exp.difference(DateTime.now());
    if (_remaining.isNegative) _remaining = Duration.zero;
  }

  void _onTick() {
    if (!mounted) return;
    final status = _payment?.status;
    if (status != null && status.isFinal) {
      _stopTimers();
      return;
    }
    setState(_recomputeRemaining);
    if (!_expired &&
        _payment?.expiresAt != null &&
        _remaining == Duration.zero) {
      setState(() => _expired = true);
      _stopTimers();
    }
  }

  Future<void> _fetch() async {
    // `_fetching` guard prevents the manual "تحقّق الآن" tap from racing the 4s
    // poll (an out-of-order older response could otherwise revert a final state).
    if (!mounted || _fetching) return;
    if (_payment?.status.isFinal ?? false) {
      _stopTimers();
      return;
    }
    _fetching = true;
    try {
      final fresh = await ref
          .read(paymentsRepositoryProvider)
          .status(widget.paymentNumber);
      if (!mounted) return;
      setState(() {
        _payment = fresh;
        _notFound = false;
        _recomputeRemaining();
      });
      if (fresh.status.isFinal) _stopTimers();
    } on ApiException catch (e) {
      if (!mounted) return;
      // 404 = unknown or non-owned number → terminal; other errors (network)
      // are transient, keep polling silently.
      if (e.isNotFound) {
        setState(() => _notFound = true);
        _stopTimers();
      }
    } finally {
      _fetching = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: Column(
        children: [
          AppHeader(
            bottomRadius: 36,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: Row(
              children: [
                const SizedBox(width: 50),
                Expanded(
                  child: Center(
                      child: Text(context.l10n.paymentStatusTitle, style: AppText.screenTitle)),
                ),
                ClayHeaderButton(
                  icon: Icons.chevron_left,
                  onTap: _leave,
                ),
              ],
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_notFound) {
      return _resultView(
        icon: Icons.error_outline,
        color: AppColors.logoutText,
        title: context.l10n.paymentNotFoundTitle,
        subtitle: context.l10n.paymentNotFoundSubtitle,
        primaryLabel: context.l10n.paymentBack,
        onPrimary: _leave,
      );
    }
    final payment = _payment;
    if (payment == null) return const LoadingState();

    switch (payment.status) {
      case PaymentStatus.paid:
        return _resultView(
          icon: Icons.check_circle_outline,
          color: AppColors.primaryGreen,
          title: context.l10n.paymentSuccessTitle,
          subtitle: context.l10n.paymentSuccessSubtitle,
          amount: payment,
          primaryLabel: context.l10n.done,
          onPrimary: _done,
          secondaryLabel: context.l10n.paymentHistoryTitle,
          onSecondary: () => context.push('/payments'),
        );
      case PaymentStatus.failed:
      case PaymentStatus.cancelled:
        return _resultView(
          icon: Icons.cancel_outlined,
          color: AppColors.logoutText,
          title: payment.status == PaymentStatus.cancelled
              ? context.l10n.paymentCancelledTitle
              : context.l10n.paymentFailedTitle,
          subtitle: context.l10n.paymentFailedSubtitle,
          amount: payment,
          primaryLabel: context.l10n.retry,
          onPrimary: _retry,
          secondaryLabel: context.l10n.paymentBack,
          onSecondary: _leave,
        );
      case PaymentStatus.refunded:
        return _resultView(
          icon: Icons.replay_circle_filled_outlined,
          color: AppColors.sectionLabel,
          title: context.l10n.paymentRefundedTitle,
          subtitle: context.l10n.paymentRefundedSubtitle,
          amount: payment,
          primaryLabel: context.l10n.paymentBack,
          onPrimary: _leave,
        );
      case PaymentStatus.pending:
      case PaymentStatus.processing:
      case PaymentStatus.unknown:
        if (_expired) {
          return _resultView(
            icon: Icons.timer_off_outlined,
            color: AppColors.logoutText,
            title: context.l10n.paymentExpiredTitle,
            subtitle: context.l10n.paymentExpiredSubtitle,
            amount: payment,
            primaryLabel: context.l10n.retry,
            onPrimary: _retry,
            secondaryLabel: context.l10n.paymentBack,
            onSecondary: _leave,
          );
        }
        // Re-opened (e.g. from history) without the transient gateway data —
        // there is no pay link/QR to show, so offer a fresh attempt instead of
        // a dead checkout. (Polling continues underneath, so if the payment is
        // completed elsewhere this flips to success on the next tick.)
        final hasGatewayData = (_redirectUrl?.isNotEmpty ?? false) ||
            (_qr?.isNotEmpty ?? false);
        if (!hasGatewayData) {
          return _resultView(
            icon: Icons.hourglass_bottom,
            color: const Color(0xFFB7791F),
            title: context.l10n.paymentPendingTitle,
            subtitle: context.l10n.paymentPendingSubtitle,
            amount: payment,
            primaryLabel: context.l10n.retry,
            onPrimary: _retry,
            secondaryLabel: context.l10n.paymentBack,
            onSecondary: _leave,
          );
        }
        return _checkout(payment);
    }
  }

  Widget _checkout(Payment payment) {
    final isFib = payment.gateway == PaymentGateway.fib;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        ClayCard(
          strong: true,
          radius: 24,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(context.l10n.paymentAmountDue, style: AppText.muted),
              const SizedBox(height: 8),
              moneyText(payment.amount, payment.currency, size: 26),
              const SizedBox(height: 6),
              Text(paymentGatewayLabel(payment.gateway, context.l10n), style: AppText.muted),
            ],
          ),
        ),
        const SizedBox(height: 22),
        if (isFib && _qr != null && _qr!.isNotEmpty) ...[
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: Clay.card(radius: 24, gradient: AppColors.surface),
              child: QrImageView(
                data: _qr!,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(context.l10n.paymentScanQr,
              textAlign: TextAlign.center, style: AppText.muted),
          const SizedBox(height: 22),
        ],
        if (_redirectUrl != null && _redirectUrl!.isNotEmpty)
          GreenPillButton(
            label: isFib ? context.l10n.paymentOpenFibApp : context.l10n.paymentOpenGateway,
            onTap: () => _launch(_redirectUrl),
          ),
        const SizedBox(height: 18),
        _waitingRow(),
        if (_payment?.expiresAt != null) ...[
          const SizedBox(height: 14),
          Center(
            child: Text(context.l10n.paymentExpiresIn(_fmtRemaining()),
                style: AppText.muted),
          ),
        ],
        const SizedBox(height: 18),
        ClayOutlineButton(
          label: context.l10n.paymentCheckNow,
          height: 56,
          onTap: _fetch,
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: _leave,
            child: Text(context.l10n.cancel,
                style: AppText.tajawal(
                    size: 14,
                    weight: AppText.bold,
                    color: AppColors.textMuted)),
          ),
        ),
      ],
    );
  }

  Widget _waitingRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
              strokeWidth: 2.4, color: AppColors.primaryGreen),
        ),
        const SizedBox(width: 12),
        Text(context.l10n.paymentWaitingConfirmation, style: AppText.rowLabel),
      ],
    );
  }

  Widget _resultView({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String primaryLabel,
    required VoidCallback onPrimary,
    Payment? amount,
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
      children: [
        Icon(icon, size: 84, color: color),
        const SizedBox(height: 20),
        Text(title,
            textAlign: TextAlign.center,
            style: AppText.tajawal(
                size: 20,
                weight: AppText.extraBold,
                color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: AppText.tajawal(
                size: 14,
                weight: AppText.regular,
                color: AppColors.textSubtleGreen,
                height: 1.7)),
        if (amount != null) ...[
          const SizedBox(height: 18),
          Center(child: moneyText(amount.amount, amount.currency, size: 20)),
        ],
        const SizedBox(height: 32),
        GreenPillButton(label: primaryLabel, onTap: onPrimary),
        if (secondaryLabel != null && onSecondary != null) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: onSecondary,
              child: Text(secondaryLabel,
                  style: AppText.tajawal(
                      size: 14,
                      weight: AppText.bold,
                      color: AppColors.primaryGreen)),
            ),
          ),
        ],
      ],
    );
  }

  String _fmtRemaining() {
    final total = _remaining.inSeconds;
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ----- navigation -----

  /// Where to go when the payment is done/abandoned. Listing payments return to
  /// My Listings (which reloads fresh); otherwise fall back to pop/home.
  void _leave() {
    final type = _payment?.payableType.toLowerCase();
    if (type == 'listing') {
      context.go('/market/my-listings');
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  void _done() => _leave();

  void _retry() {
    final payment = _payment;
    if (payment == null) {
      _leave();
      return;
    }
    // Only `listing` is a registered payable today; the picker route uses the
    // lowercase config key.
    context.pushReplacement(
        '/pay/${payment.payableType.toLowerCase()}/${payment.payableId}');
  }
}
