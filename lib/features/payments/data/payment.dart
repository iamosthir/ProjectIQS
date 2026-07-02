import 'package:flutter/foundation.dart';

import 'package:iqs_flutter/core/util/date_fmt.dart';
import 'package:iqs_flutter/shared/l10n/app_localizations.dart';

/// Payment lifecycle status (`status`). Final states stop polling.
enum PaymentStatus {
  pending,
  processing,
  paid,
  failed,
  cancelled,
  refunded,
  unknown;

  bool get isFinal =>
      this == paid || this == failed || this == cancelled || this == refunded;

  bool get isSuccess => this == paid;
}

PaymentStatus paymentStatusFrom(String? s) {
  switch (s) {
    case 'pending':
      return PaymentStatus.pending;
    case 'processing':
      return PaymentStatus.processing;
    case 'paid':
      return PaymentStatus.paid;
    case 'failed':
      return PaymentStatus.failed;
    case 'cancelled':
      return PaymentStatus.cancelled;
    case 'refunded':
      return PaymentStatus.refunded;
    default:
      return PaymentStatus.unknown;
  }
}

String paymentStatusLabel(PaymentStatus s, AppLocalizations l) {
  switch (s) {
    case PaymentStatus.pending:
      return l.paymentStatusPending;
    case PaymentStatus.processing:
      return l.paymentStatusProcessing;
    case PaymentStatus.paid:
      return l.paymentStatusPaid;
    case PaymentStatus.failed:
      return l.paymentStatusFailed;
    case PaymentStatus.cancelled:
      return l.paymentStatusCancelled;
    case PaymentStatus.refunded:
      return l.paymentStatusRefunded;
    case PaymentStatus.unknown:
      return '';
  }
}

/// Payment gateway. Only `zaincash`/`fib` are customer-selectable; `manual` is
/// admin-only and never sent — kept here so reads (history) parse cleanly.
enum PaymentGateway {
  zaincash,
  fib,
  manual,
  unknown;

  String get value {
    switch (this) {
      case PaymentGateway.zaincash:
        return 'zaincash';
      case PaymentGateway.fib:
        return 'fib';
      case PaymentGateway.manual:
        return 'manual';
      case PaymentGateway.unknown:
        return '';
    }
  }
}

String paymentGatewayLabel(PaymentGateway g, AppLocalizations l) {
  switch (g) {
    case PaymentGateway.zaincash:
      return l.paymentGatewayZaincash;
    case PaymentGateway.fib:
      return 'FIB';
    case PaymentGateway.manual:
      return l.paymentGatewayManual;
    case PaymentGateway.unknown:
      return '';
  }
}

PaymentGateway paymentGatewayFrom(String? s) {
  switch (s) {
    case 'zaincash':
      return PaymentGateway.zaincash;
    case 'fib':
      return PaymentGateway.fib;
    case 'manual':
      return PaymentGateway.manual;
    default:
      return PaymentGateway.unknown;
  }
}

/// A payment (`/payments*`). `redirectUrl`/`qr` are **transient** — present only
/// on the `initiate` response, null on subsequent `status` reads.
@immutable
class Payment {
  const Payment({
    required this.id,
    required this.paymentNumber,
    required this.gateway,
    required this.amount,
    required this.currency,
    required this.status,
    required this.payableType,
    required this.payableId,
    this.redirectUrl,
    this.qr,
    this.paidAt,
    this.expiresAt,
    this.createdAt,
  });

  final int id;
  final String paymentNumber;
  final PaymentGateway gateway;
  final double amount;
  final String currency;
  final PaymentStatus status;

  /// Class basename from the API (e.g. `Listing`).
  final String payableType;
  final int payableId;

  final String? redirectUrl;
  final String? qr;
  final DateTime? paidAt;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  /// The resource forces `(float)`, but parse defensively: a Laravel
  /// `decimal:N` cast can serialize as a JSON string elsewhere.
  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  factory Payment.fromJson(Map<String, dynamic> j) {
    final payable = (j['payable'] as Map?)?.cast<String, dynamic>() ?? const {};
    return Payment(
      id: (j['id'] as num?)?.toInt() ?? 0,
      paymentNumber: j['payment_number']?.toString() ?? '',
      gateway: paymentGatewayFrom(j['gateway'] as String?),
      amount: _toDouble(j['amount']),
      currency: j['currency']?.toString() ?? 'IQD',
      status: paymentStatusFrom(j['status'] as String?),
      payableType: payable['type']?.toString() ?? '',
      payableId: (payable['id'] as num?)?.toInt() ?? 0,
      redirectUrl: j['redirect_url'] as String?,
      qr: j['qr'] as String?,
      paidAt: DateFmt.tryParse(j['paid_at'] as String?),
      expiresAt: DateFmt.tryParse(j['expires_at'] as String?),
      createdAt: DateFmt.tryParse(j['created_at'] as String?),
    );
  }
}
