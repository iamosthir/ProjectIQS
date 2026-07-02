import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:iqs_flutter/core/util/date_fmt.dart';
import 'package:iqs_flutter/features/payments/application/payments_providers.dart';
import 'package:iqs_flutter/features/payments/data/payment.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/shared/widgets/paginated_list_view.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';
import 'package:iqs_flutter/widgets/app_header.dart';
import 'package:iqs_flutter/widgets/clay_card.dart';
import 'package:iqs_flutter/widgets/clay_icon_button.dart';
import 'payment_widgets.dart';

/// Payment history (`/payments`) — paginated, newest-first.
class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      child:
                          Text(context.l10n.paymentHistoryTitle, style: AppText.screenTitle)),
                ),
                ClayHeaderButton(
                  icon: Icons.chevron_left,
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/more'),
                ),
              ],
            ),
          ),
          Expanded(
            child: PaginatedListView<Payment>(
              loader: (page) =>
                  ref.read(paymentsRepositoryProvider).history(page: page),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              emptyTitle: context.l10n.paymentHistoryEmpty,
              itemBuilder: (context, p, _) => _PaymentRow(payment: p),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment});
  final Payment payment;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/pay/status/${payment.paymentNumber}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(payment.paymentNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: AppText.tajawal(
                          size: 13,
                          weight: AppText.bold,
                          color: AppColors.textPrimary)),
                ),
              ),
              const SizedBox(width: 8),
              paymentStatusPill(context, payment.status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              moneyText(payment.amount, payment.currency, size: 16),
              Text(paymentGatewayLabel(payment.gateway, context.l10n), style: AppText.muted),
            ],
          ),
          if (payment.createdAt != null) ...[
            const SizedBox(height: 6),
            Text(DateFmt.relative(payment.createdAt!), style: AppText.muted),
          ],
        ],
      ),
    );
  }
}
