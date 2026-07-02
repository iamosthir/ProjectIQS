import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:iqs_flutter/features/payments/data/payment.dart';
import 'package:iqs_flutter/shared/l10n/l10n_ext.dart';
import 'package:iqs_flutter/theme/app_colors.dart';
import 'package:iqs_flutter/theme/app_text_styles.dart';

final _amountFmt = NumberFormat('#,###', 'en');

/// Formats an amount + currency, forced LTR (inert numeric data).
Widget moneyText(double amount, String currency,
    {double size = 16, Color? color, FontWeight? weight}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Text(
      '${_amountFmt.format(amount)} $currency',
      style: AppText.tajawal(
          size: size,
          weight: weight ?? AppText.extraBold,
          color: color ?? AppColors.textPrimary),
    ),
  );
}

/// (background, foreground) colors for a payment status pill, using existing
/// theme tokens / the same warm-amber the marketplace `pending_payment` chip uses.
(Color, Color) paymentStatusColors(PaymentStatus s) {
  switch (s) {
    case PaymentStatus.paid:
      return (AppColors.pillBg, AppColors.pillText);
    case PaymentStatus.failed:
    case PaymentStatus.cancelled:
      return (AppColors.logoutBgBottom, AppColors.logoutText);
    case PaymentStatus.pending:
    case PaymentStatus.processing:
      return (const Color(0xFFFFF3D6), const Color(0xFFB7791F));
    case PaymentStatus.refunded:
    case PaymentStatus.unknown:
      return (const Color(0xFFEDEFF1), AppColors.sectionLabel);
  }
}

Widget paymentStatusPill(BuildContext context, PaymentStatus s) {
  final (bg, fg) = paymentStatusColors(s);
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
    child: Text(paymentStatusLabel(s, context.l10n),
        style: AppText.tajawal(size: 12, weight: AppText.bold, color: fg)),
  );
}
