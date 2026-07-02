import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/core/network/api_exception.dart';
import 'package:iqs_flutter/features/payments/application/payments_providers.dart';
import 'package:iqs_flutter/features/payments/data/payment.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/app_states.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/theme/clay.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_card.dart';
import 'package:iqs_flutter/widgets/clay_icon_button.dart';

/// Payment method picker (`/pay/:payableType/:id`). Pick ZainCash or FIB, then
/// initiate — the server derives amount/currency. On success we hand the
/// (transient) initiated [Payment] to the status screen via `extra`.
class PaymentMethodScreen extends ConsumerStatefulWidget {
  const PaymentMethodScreen({
    super.key,
    required this.payableType,
    required this.payableId,
  });

  final String payableType;
  final int payableId;

  @override
  ConsumerState<PaymentMethodScreen> createState() =>
      _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends ConsumerState<PaymentMethodScreen> {
  PaymentGateway _gateway = PaymentGateway.zaincash;
  bool _loading = false;

  Future<void> _continue() async {
    setState(() => _loading = true);
    try {
      final payment = await ref.read(paymentsRepositoryProvider).initiate(
            payableType: widget.payableType,
            payableId: widget.payableId,
            gateway: _gateway.value,
          );
      if (!mounted) return;
      // Replace the picker so Back from the checkout returns to the origin
      // (e.g. My Listings), not the picker. Carry the transient redirect/qr.
      context.pushReplacement('/pay/status/${payment.paymentNumber}',
          extra: payment);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
      setState(() => _loading = false);
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
                      child: Text(context.l10n.paymentMethodTitle, style: AppText.screenTitle)),
                ),
                ClayHeaderButton(
                  icon: Icons.chevron_left,
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/home'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
              children: [
                Text(context.l10n.paymentMethodChoose, style: AppText.sectionHeader),
                const SizedBox(height: 16),
                _methodCard(
                  gateway: PaymentGateway.zaincash,
                  icon: Icons.account_balance_wallet_outlined,
                  subtitle: context.l10n.paymentMethodZaincashSubtitle,
                ),
                const SizedBox(height: 12),
                _methodCard(
                  gateway: PaymentGateway.fib,
                  icon: Icons.qr_code_2,
                  subtitle: context.l10n.paymentMethodFibSubtitle,
                ),
                const SizedBox(height: 28),
                _loading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LoadingState())
                    : GreenPillButton(label: context.l10n.paymentMethodContinue, onTap: _continue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodCard({
    required PaymentGateway gateway,
    required IconData icon,
    required String subtitle,
  }) {
    final selected = _gateway == gateway;
    return ClayCard(
      radius: 20,
      padding: const EdgeInsets.all(16),
      onTap: _loading ? null : () => setState(() => _gateway = gateway),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: Clay.settingsTile(),
            child: Icon(icon, size: 24, color: AppColors.primaryGreen),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(paymentGatewayLabel(gateway, context.l10n),
                    style: AppText.tajawal(
                        size: 16,
                        weight: AppText.extraBold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text(subtitle, style: AppText.muted),
              ],
            ),
          ),
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: selected ? AppColors.primaryGreen : AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
